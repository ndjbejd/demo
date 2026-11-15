-- =====================================================================
-- ĐỒ ÁN 12: CSDL NGÂN HÀNG CÂU HỎI & THI TRỰC TUYẾN CÓ QUẢN LÝ PHIÊN BẢN
-- Học phần: Cơ sở dữ liệu nâng cao - Trường Đại học Sài Gòn (SGU)
-- Nhóm 27: Nguyễn Mạnh Dũng (3123410050) - Khưu Minh Đức (3123410083)
-- File: 04_transactions.sql (Cài đặt các Stored Procedure phục vụ Mục 6.7 Chương 6)
-- Bao gồm:
--   1. sp_luu_cau_tra_loi: Transaction lưu bài tự động (Autosave / Manual Save)
--   2. sp_nop_bai_va_chot_diem: Transaction nộp bài có khóa bi quan (SELECT FOR UPDATE)
--   3. sp_cham_tu_luan_va_chot_ket_qua: Chấm tự luận và hoàn tất lượt thi
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. THỦ TỤC LƯU BÀI TỰ ĐỘNG (AUTOSAVE TRANSACTION)
-- Nghiệp vụ: BR15, BR17, BR18
-- Đảm bảo: Chỉ cho phép lưu khi trạng thái = 'DANG_LAM' và chưa quá hạn nộp.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_luu_cau_tra_loi(
    p_ma_luot_thi      BIGINT,
    p_ma_chi_tiet_de   INTEGER,
    p_noi_dung_tu_luan TEXT,
    p_danh_sach_pa     INTEGER[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_trang_thai       VARCHAR(15);
    v_han_nop          TIMESTAMPTZ;
    v_ma_cau_tra_loi   BIGINT;
    v_pa_id            INTEGER;
BEGIN
    -- Bước 1: Kiểm tra trạng thái lượt thi và thời hạn làm bài (BR17, BR18)
    SELECT trang_thai, han_nop_bai 
    INTO v_trang_thai, v_han_nop
    FROM luot_thi
    WHERE ma_luot_thi = p_ma_luot_thi;

    IF v_trang_thai IS NULL THEN
        RAISE EXCEPTION 'Lượt thi % không tồn tại trong hệ thống!', p_ma_luot_thi;
    END IF;

    -- Chặn ghi nếu bài đã nộp hoặc kết thúc
    IF v_trang_thai <> 'DANG_LAM' THEN
        RAISE EXCEPTION 'Lượt thi % đã ở trạng thái %, không được phép lưu hoặc ghi đè!', 
            p_ma_luot_thi, v_trang_thai;
    END IF;

    -- Chặn nếu quá hạn nộp bài
    IF now() > v_han_nop THEN
        RAISE EXCEPTION 'Lượt thi % đã quá thời hạn nộp bài (Hạn nộp: %)!', 
            p_ma_luot_thi, v_han_nop;
    END IF;

    -- Bước 2: Thêm mới hoặc cập nhật câu trả lời (Idempotent UPSERT - BR16)
    INSERT INTO cau_tra_loi (ma_luot_thi, ma_chi_tiet_de, noi_dung_tu_luan, lan_cap_nhat, thoi_gian_cap_nhat)
    VALUES (p_ma_luot_thi, p_ma_chi_tiet_de, p_noi_dung_tu_luan, 1, now())
    ON CONFLICT (ma_luot_thi, ma_chi_tiet_de) DO UPDATE
    SET noi_dung_tu_luan   = EXCLUDED.noi_dung_tu_luan,
        lan_cap_nhat       = cau_tra_loi.lan_cap_nhat + 1,
        thoi_gian_cap_nhat = now()
    RETURNING ma_cau_tra_loi INTO v_ma_cau_tra_loi;

    -- Bước 3: Cập nhật tập phương án trắc nghiệm được chọn
    IF p_danh_sach_pa IS NOT NULL THEN
        DELETE FROM lua_chon_tra_loi WHERE ma_cau_tra_loi = v_ma_cau_tra_loi;
        FOREACH v_pa_id IN ARRAY p_danh_sach_pa
        LOOP
            INSERT INTO lua_chon_tra_loi (ma_cau_tra_loi, ma_phuong_an)
            VALUES (v_ma_cau_tra_loi, v_pa_id)
            ON CONFLICT DO NOTHING;
        END LOOP;
    END IF;
END;
$$;


-- ---------------------------------------------------------------------
-- 2. THỦ TỤC NỘP BÀI VÀ CHỐT ĐIỂM (SUBMIT TRANSACTION - KHÓA BI QUAN)
-- Nghiệp vụ: BR18, BR19, BR20, BR21, BR22, BR23, BR24
-- Đảm bảo: Khóa độc quyền dòng luot_thi, chống nộp lặp và chống chấm trùng
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_nop_bai_va_chot_diem(
    p_ma_luot_thi BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_trang_thai        VARCHAR(15);
    v_so_cau_cho_cham   INTEGER;
    v_tong_diem         NUMERIC(7,2);
BEGIN
    -- Bước 1: KHÓA BI QUAN ĐỘC QUYỀN (Pessimistic Row Lock - BR21)
    -- Chặn đứng các phiên Autosave hoặc Submit khác đang cố truy cập cùng lượt thi
    SELECT trang_thai 
    INTO v_trang_thai
    FROM luot_thi
    WHERE ma_luot_thi = p_ma_luot_thi
    FOR UPDATE;

    IF v_trang_thai IS NULL THEN
        RAISE EXCEPTION 'Lượt thi % không tồn tại!', p_ma_luot_thi;
    END IF;

    -- Chống nộp lặp (Double Submission / BR20): Nếu trạng thái không phải DANG_LAM thì ngắt ngay
    IF v_trang_thai <> 'DANG_LAM' THEN
        RAISE EXCEPTION 'Lượt thi % đã được nộp hoặc xử lý trước đó (Trạng thái hiện tại: %)!', 
            p_ma_luot_thi, v_trang_thai;
    END IF;

    -- Bước 2: Chuyển trạng thái sang DA_NOP và ghi nhận thoi_gian_nop (BR18, BR19)
    UPDATE luot_thi
    SET trang_thai    = 'DA_NOP',
        thoi_gian_nop = now()
    WHERE ma_luot_thi = p_ma_luot_thi;

    -- Bước 3: Chấm tự động tất cả các câu hỏi trắc nghiệm (BR23)
    -- Sử dụng hàm fn_tinh_diem_trac_nghiem đã cài đặt ở Mục 5.5.1
    INSERT INTO chi_tiet_cham (ma_cau_tra_loi, diem_dat_duoc, trang_thai_cham, thoi_gian_cham, nhan_xet)
    SELECT 
        ctl.ma_cau_tra_loi,
        fn_tinh_diem_trac_nghiem(ctl.ma_cau_tra_loi) AS diem_dat_duoc,
        'DA_CHAM' AS trang_thai_cham,
        now() AS thoi_gian_cham,
        'Chấm tự động khi nộp bài' AS nhan_xet
    FROM cau_tra_loi ctl
    JOIN cau_hoi_trong_de chtd ON ctl.ma_chi_tiet_de = chtd.ma_chi_tiet_de
    JOIN phien_ban_cau_hoi pbch ON chtd.ma_phien_ban_ch = pbch.ma_phien_ban_ch
    JOIN cau_hoi ch ON pbch.ma_cau_hoi = ch.ma_cau_hoi
    WHERE ctl.ma_luot_thi = p_ma_luot_thi
      AND ch.loai_cau_hoi IN ('MOT_DAP_AN', 'NHIEU_DAP_AN')
    ON CONFLICT (ma_cau_tra_loi) DO UPDATE 
    SET diem_dat_duoc   = EXCLUDED.diem_dat_duoc,
        trang_thai_cham = 'DA_CHAM',
        thoi_gian_cham  = now(),
        nhan_xet        = EXCLUDED.nhan_xet;

    -- Bước 4: Khởi tạo bản ghi CHO_CHAM cho câu hỏi tự luận (BR24)
    INSERT INTO chi_tiet_cham (ma_cau_tra_loi, diem_dat_duoc, trang_thai_cham, nhan_xet)
    SELECT 
        ctl.ma_cau_tra_loi,
        NULL,
        'CHO_CHAM',
        'Chờ giảng viên chấm thủ công'
    FROM cau_tra_loi ctl
    JOIN cau_hoi_trong_de chtd ON ctl.ma_chi_tiet_de = chtd.ma_chi_tiet_de
    JOIN phien_ban_cau_hoi pbch ON chtd.ma_phien_ban_ch = pbch.ma_phien_ban_ch
    JOIN cau_hoi ch ON pbch.ma_cau_hoi = ch.ma_cau_hoi
    WHERE ctl.ma_luot_thi = p_ma_luot_thi
      AND ch.loai_cau_hoi = 'TU_LUAN'
    ON CONFLICT (ma_cau_tra_loi) DO NOTHING;

    -- Bước 5: Phân nhánh trạng thái và chốt kết quả (BR22, BR24)
    SELECT COUNT(*) INTO v_so_cau_cho_cham
    FROM cau_tra_loi ctl
    JOIN chi_tiet_cham ctc ON ctl.ma_cau_tra_loi = ctc.ma_cau_tra_loi
    WHERE ctl.ma_luot_thi = p_ma_luot_thi 
      AND ctc.trang_thai_cham = 'CHO_CHAM';

    IF v_so_cau_cho_cham > 0 THEN
        -- Đề còn câu tự luận -> Chuyển sang CHO_CHAM, chưa ghi nhận kết quả chính thức (BR24)
        UPDATE luot_thi SET trang_thai = 'CHO_CHAM' WHERE ma_luot_thi = p_ma_luot_thi;
    ELSE
        -- Đề thi 100% trắc nghiệm -> Xác lập kết quả chính thức duy nhất (BR22)
        SELECT COALESCE(SUM(ctc.diem_dat_duoc), 0.00)
        INTO v_tong_diem
        FROM cau_tra_loi ctl
        JOIN chi_tiet_cham ctc ON ctl.ma_cau_tra_loi = ctc.ma_cau_tra_loi
        WHERE ctl.ma_luot_thi = p_ma_luot_thi;

        INSERT INTO ket_qua (ma_luot_thi, tong_diem, thoi_gian_hoan_tat, trang_thai_ket_qua)
        VALUES (p_ma_luot_thi, v_tong_diem, now(), 'CHINH_THUC')
        ON CONFLICT (ma_luot_thi) DO UPDATE
        SET tong_diem = EXCLUDED.tong_diem,
            thoi_gian_hoan_tat = now();

        UPDATE luot_thi SET trang_thai = 'HOAN_TAT' WHERE ma_luot_thi = p_ma_luot_thi;
    END IF;
END;
$$;
