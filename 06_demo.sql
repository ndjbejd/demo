-- =====================================================================
-- ĐỒ ÁN 12: CSDL NGÂN HÀNG CÂU HỎI & THI TRỰC TUYẾN CÓ QUẢN LÝ PHIÊN BẢN
-- Học phần: Cơ sở dữ liệu nâng cao - Trường Đại học Sài Gòn (SGU)
-- Nhóm 27: Nguyễn Mạnh Dũng (3123410050) - Khưu Minh Đức (3123410083)
-- File: 06_demo.sql (Kịch bản trình diễn Live Demo đồng bộ 100% với Báo cáo Chương 7)
-- Đồng bộ chính xác từng ID, từng câu lệnh với Hình 7.1 -> Hình 7.13 trong CSDLNC.pdf
-- =====================================================================

-- =====================================================================
-- PHẦN 1: TỔNG QUAN TRƯỚC KIỂM THỬ (Khớp Hình 7.1 trang 116 Báo cáo)
-- Hiển thị hiện trạng 6 lượt thi trong dữ liệu thực nghiệm
-- =====================================================================
SELECT 
    lt.ma_luot_thi,
    nd.ho_ten,
    pbde.so_phien_ban AS ban_de,
    lt.trang_thai,
    kq.tong_diem
FROM luot_thi lt
JOIN nguoi_dung nd ON lt.ma_nguoi_dung = nd.ma_nguoi_dung
JOIN phien_ban_de_thi pbde ON lt.ma_phien_ban_de = pbde.ma_phien_ban_de
LEFT JOIN ket_qua kq ON lt.ma_luot_thi = kq.ma_luot_thi
ORDER BY lt.ma_luot_thi ASC;


-- =====================================================================
-- BƯỚC 3 TRONG FLOW DEMO (50s): TÁI HIỆN ĐỀ THI LỊCH SỬ (Khớp Mục 7.2)
-- Chứng minh Yêu cầu 1: Đề đã thi không bị thay đổi dù ngân hàng câu hỏi cập nhật
-- =====================================================================

-- 3.1. Truy xuất nội dung, phiên bản và phương án của Lượt thi số 1 (Khớp Hình 7.2 trang 117):
SELECT 
    lt.ma_luot_thi,
    chtd.thu_tu_cau_hoi,
    pbch.so_phien_ban,
    pbch.noi_dung,
    pa.noi_dung_phuong_an,
    pa.la_dap_an_dung
FROM luot_thi lt
JOIN phien_ban_de_thi pbde ON lt.ma_phien_ban_de = pbde.ma_phien_ban_de
JOIN cau_hoi_trong_de chtd ON pbde.ma_phien_ban_de = chtd.ma_phien_ban_de
JOIN phien_ban_cau_hoi pbch ON chtd.ma_phien_ban_ch = pbch.ma_phien_ban_ch
JOIN phuong_an pa ON pbch.ma_phien_ban_ch = pa.ma_phien_ban_ch
WHERE lt.ma_luot_thi = 1
ORDER BY chtd.thu_tu_cau_hoi ASC, pa.thu_tu ASC;

-- 3.2. Kiểm thử Trigger trg_bao_toan_phien_ban_cau_hoi chặn sửa phiên bản đã công bố (Khớp Hình 7.3 trang 118):
-- Dự kiến bị từ chối và phát sinh lỗi ngoại lệ từ trigger
BEGIN;
UPDATE phien_ban_cau_hoi
SET noi_dung = 'Nội dung bị sửa đổi trái phép sau kỳ thi'
WHERE ma_phien_ban_ch = 1;
ROLLBACK;

-- 3.3. Kiểm tra hai phiên bản v1 và v2 của Câu hỏi 1 (Khớp Hình 7.4 & 7.5 trang 119 - 120):
-- Chứng minh: Câu hỏi 1 có 2 phiên bản độc lập (Mã PB #1 và #2)
SELECT 
    ma_phien_ban_ch,
    ma_cau_hoi,
    so_phien_ban,
    noi_dung,
    muc_do_kho,
    quy_tac_cham,
    trang_thai_phien_ban
FROM phien_ban_cau_hoi
WHERE ma_cau_hoi = 1
ORDER BY so_phien_ban ASC;

-- 3.4. Kiểm tra Lượt thi 1 vẫn duy trì tham chiếu đến phiên bản #1 (Khớp Hình 7.5 trang 120):
SELECT 
    lt.ma_luot_thi,
    nd.ho_ten,
    chtd.thu_tu_cau_hoi,
    pbch.ma_phien_ban_ch,
    pbch.so_phien_ban,
    chtd.diem_toi_da
FROM luot_thi lt
JOIN nguoi_dung nd ON lt.ma_nguoi_dung = nd.ma_nguoi_dung
JOIN phien_ban_de_thi pbde ON lt.ma_phien_ban_de = pbde.ma_phien_ban_de
JOIN cau_hoi_trong_de chtd ON pbde.ma_phien_ban_de = chtd.ma_phien_ban_de
JOIN phien_ban_cau_hoi pbch ON chtd.ma_phien_ban_ch = pbch.ma_phien_ban_ch
WHERE lt.ma_luot_thi = 1
ORDER BY chtd.thu_tu_cau_hoi ASC;


-- =====================================================================
-- BƯỚC 5 TRONG FLOW DEMO (50s): NỘP LẶP VÀ CHỐNG CHẤM TRÙNG (Khớp Mục 7.4 & 7.6)
-- Chứng minh Yêu cầu 3: Không ghi kết quả hay chấm trùng
-- =====================================================================

-- 5.1. Kiểm thử điều kiện ngăn chuyển trạng thái khi nộp bài lặp (Khớp Hình 7.9 trang 126):
-- Thử cập nhật lượt thi 1 đã HOAN_TAT với điều kiện trang_thai = 'DANG_LAM'
-- Kết quả trả về: UPDATE 0 (không bản ghi nào bị cập nhật lặp)
UPDATE luot_thi
SET trang_thai = 'DA_NOP',
    thoi_gian_nop = now()
WHERE ma_luot_thi = 1
  AND trang_thai = 'DANG_LAM'
RETURNING ma_luot_thi, trang_thai;

-- 5.2. Kiểm tra số lượng bản ghi kết quả theo từng lượt thi (Khớp Hình 7.11 trang 130):
-- Kết quả: Mỗi lượt thi hoàn tất chỉ có đúng 1 bản ghi duy nhất trong bảng ket_qua
SELECT 
    ma_luot_thi,
    COUNT(ma_ket_qua) AS so_luong_ket_qua
FROM ket_qua
GROUP BY ma_luot_thi
ORDER BY ma_luot_thi ASC;

-- 5.3. Kiểm thử ràng buộc UNIQUE ngăn ghi nhận kết quả trùng lặp (Khớp Hình 7.12 trang 131):
-- Cố tình thêm kết quả lần 2 cho Lượt thi số 1 -> Bị từ chối bởi lỗi 23505 (uq_ket_qua_luot_thi)
INSERT INTO ket_qua (ma_luot_thi, tong_diem, thoi_gian_hoan_tat, trang_thai_ket_qua)
VALUES (1, 10.00, now(), 'CHINH_THUC');


-- =====================================================================
-- BƯỚC 6 TRONG FLOW DEMO (40s): ROLLBACK (Khớp Mục 7.3 - Hình 7.6 trang 122)
-- Chứng minh Tính nguyên tử ACID: Không để dữ liệu cập nhật dở dang
-- =====================================================================

-- 6.1. Kiểm tra thuộc tính lan_cap_nhat ban đầu của câu trả lời số 20 (thuộc lượt thi 6)
SELECT ma_cau_tra_loi, lan_cap_nhat, thoi_gian_cap_nhat 
FROM cau_tra_loi 
WHERE ma_cau_tra_loi = 20;

-- 6.2. Thực nghiệm hoàn tác giao dịch cập nhật câu trả lời bằng ROLLBACK (Khớp Hình 7.6):
BEGIN;

UPDATE cau_tra_loi
SET lan_cap_nhat = lan_cap_nhat + 1,
    thoi_gian_cap_nhat = now()
WHERE ma_cau_tra_loi = 20;

-- Hoàn tác toàn bộ thay đổi trong giao dịch
ROLLBACK;

-- 6.3. Kiểm tra lại: Giá trị lan_cap_nhat vẫn giữ nguyên là 2 (không bị tăng lên 3)!
SELECT ma_cau_tra_loi, lan_cap_nhat, thoi_gian_cap_nhat 
FROM cau_tra_loi 
WHERE ma_cau_tra_loi = 20;
