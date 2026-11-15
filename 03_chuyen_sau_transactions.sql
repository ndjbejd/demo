-- =====================================================================
-- Đồ án 12: CSDL ngân hàng câu hỏi & thi trực tuyến có quản lý phiên bản
-- Học phần: Cơ sở dữ liệu nâng cao - Trường Đại học Sài Gòn (SGU)
-- Nhóm 27: Nguyễn Mạnh Dũng (3123410050) - Khưu Minh Đức (3123410083)
-- File 03: Script kiểm thử các giao dịch chuyên sâu Chương 6 (Transactions & OQL Mapping)
-- Phục vụ: Mục 6.6 & Mục 6.7 trong Báo cáo Đồ án
-- =====================================================================

-- =====================================================================
-- PHẦN 1: TRUY VẤN TÁI HIỆN ĐỀ THI LỊCH SỬ (Ánh xạ OQL 2 sang PostgreSQL)
-- Kiểm tra: Lượt thi số 1 (Nguyễn Mạnh Dũng) bảo toàn chính xác phiên bản đề cũ
-- =====================================================================
SELECT 
    lt.ma_luot_thi,
    nd.ho_ten AS ho_ten_thi_sinh,
    dt.ten_de_thi,
    pbde.so_phien_ban AS so_phien_ban_de,
    chtd.thu_tu_cau_hoi,
    pbch.noi_dung AS noi_dung_cau_hoi,
    pbch.so_phien_ban AS phien_ban_cau_hoi_da_thi,
    chtd.diem_toi_da,
    ctl.noi_dung_tu_luan,
    array_remove(array_agg(lctl.ma_phuong_an ORDER BY pa.thu_tu), NULL) AS cac_ma_phuong_an_da_chon,
    ctc.diem_dat_duoc,
    ctc.trang_thai_cham
FROM luot_thi lt
JOIN nguoi_dung nd ON lt.ma_nguoi_dung = nd.ma_nguoi_dung
JOIN phien_ban_de_thi pbde ON lt.ma_phien_ban_de = pbde.ma_phien_ban_de
JOIN de_thi dt ON pbde.ma_de_thi = dt.ma_de_thi
JOIN cau_hoi_trong_de chtd ON pbde.ma_phien_ban_de = chtd.ma_phien_ban_de
JOIN phien_ban_cau_hoi pbch ON chtd.ma_phien_ban_ch = pbch.ma_phien_ban_ch
LEFT JOIN cau_tra_loi ctl ON lt.ma_luot_thi = ctl.ma_luot_thi 
                          AND chtd.ma_chi_tiet_de = ctl.ma_chi_tiet_de
LEFT JOIN lua_chon_tra_loi lctl ON ctl.ma_cau_tra_loi = lctl.ma_cau_tra_loi
LEFT JOIN phuong_an pa ON lctl.ma_phuong_an = pa.ma_phuong_an
LEFT JOIN chi_tiet_cham ctc ON ctl.ma_cau_tra_loi = ctc.ma_cau_tra_loi
WHERE lt.ma_luot_thi = 1
GROUP BY 
    lt.ma_luot_thi, nd.ho_ten, dt.ten_de_thi, pbde.so_phien_ban, 
    chtd.thu_tu_cau_hoi, pbch.noi_dung, pbch.so_phien_ban, 
    chtd.diem_toi_da, ctl.noi_dung_tu_luan, ctc.diem_dat_duoc, ctc.trang_thai_cham
ORDER BY chtd.thu_tu_cau_hoi ASC;


-- =====================================================================
-- PHẦN 2: THỦ TỤC THỰC HIỆN GIAO DỊCH LƯU BÀI TỰ ĐỘNG (AUTOSAVE TRANSACTION)
-- Kiểm tra: Chỉ cho phép lưu khi trạng thái = DANG_LAM và chưa hết giờ
-- =====================================================================
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
        RAISE EXCEPTION 'Lượt thi % không tồn tại!', p_ma_luot_thi;
    END IF;

    IF v_trang_thai <> 'DANG_LAM' THEN
        RAISE EXCEPTION 'Lượt thi % đã ở trạng thái %, không được phép lưu tiếp!', 
            p_ma_luot_thi, v_trang_thai;
    END IF;

    IF now() > v_han_nop THEN
        RAISE EXCEPTION 'Lượt thi % đã quá thời hạn nộp bài!', p_ma_luot_thi;
    END IF;

    -- Bước 2: UPSERT vào bảng cau_tra_loi
    INSERT INTO cau_tra_loi (ma_luot_thi, ma_chi_tiet_de, noi_dung_tu_luan, lan_cap_nhat, thoi_gian_cap_nhat)
    VALUES (p_ma_luot_thi, p_ma_chi_tiet_de, p_noi_dung_tu_luan, 1, now())
    ON CONFLICT (ma_luot_thi, ma_chi_tiet_de) DO UPDATE
    SET noi_dung_tu_luan   = EXCLUDED.noi_dung_tu_luan,
        lan_cap_nhat       = cau_tra_loi.lan_cap_nhat + 1,
        thoi_gian_cap_nhat = now()
    RETURNING ma_cau_tra_loi INTO v_ma_cau_tra_loi;

    -- Bước 3: Cập nhật danh sách phương án trắc nghiệm (nếu có)
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


-- =====================================================================
-- PHẦN 3: THỦ TỤC NỘP BÀI KHÓA BI QUAN & CHỐT ĐIỂM (SUBMIT TRANSACTION)
-- Sử dụng SELECT FOR UPDATE ngăn chặn hoàn toàn nộp bài lặp và race condition
-- =====================================================================
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
    -- Bước 1: Khóa bi quan độc quyền dòng lượt thi (Pessimistic Row Lock)
    SELECT trang_thai 
    INTO v_trang_thai
    FROM luot_thi
    WHERE ma_luot_thi = p_ma_luot_thi
    FOR UPDATE;

    IF v_trang_thai IS NULL THEN
        RAISE EXCEPTION 'Lượt thi % không tồn tại!', p_ma_luot_thi;
    END IF;

    -- Chống nộp bài lặp: Nếu khác DANG_LAM thì ngắt ngay
    IF v_trang_thai <> 'DANG_LAM' THEN
        RAISE EXCEPTION 'Lượt thi % đã được nộp hoặc xử lý trước đó (Trạng thái: %)!', 
            p_ma_luot_thi, v_trang_thai;
    END IF;

    -- Bước 2: Chuyển trạng thái lượt thi sang DA_NOP và ghi nhận thời gian nộp
    UPDATE luot_thi
    SET trang_thai    = 'DA_NOP',
        thoi_gian_nop = now()
    WHERE ma_luot_thi = p_ma_luot_thi;

    -- Bước 3: Chấm tự động cho tất cả các câu hỏi trắc nghiệm
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

    -- Bước 4: Khởi tạo bản ghi CHO_CHAM cho câu hỏi tự luận
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

    -- Bước 5: Kiểm tra xem còn câu tự luận cần chấm hay không
    SELECT COUNT(*) INTO v_so_cau_cho_cham
    FROM cau_tra_loi ctl
    JOIN chi_tiet_cham ctc ON ctl.ma_cau_tra_loi = ctc.ma_cau_tra_loi
    WHERE ctl.ma_luot_thi = p_ma_luot_thi 
      AND ctc.trang_thai_cham = 'CHO_CHAM';

    IF v_so_cau_cho_cham > 0 THEN
        UPDATE luot_thi SET trang_thai = 'CHO_CHAM' WHERE ma_luot_thi = p_ma_luot_thi;
    ELSE
        -- Đề thi 100% trắc nghiệm -> Xác lập kết quả chính thức ngay (BR22)
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
