-- =====================================================================
-- BƯỚC 4: THỰC NGHIỆM ĐỒNG THỜI (CONCURRENCY) - CỬA SỔ QUERY TOOL B
-- Đồ án 12: CSDL ngân hàng câu hỏi & thi trực tuyến có quản lý phiên bản
-- Khớp 100% với Mục 7.4 trong Báo cáo CSDLNC.pdf (Hình 7.8 trang 124)
-- Đối tượng thử nghiệm: Lượt thi số 6 (cùng bản ghi với Phiên A)
-- =====================================================================

-- ---------------------------------------------------------------------
-- THAO TÁC B1: Chạy khi Phiên A đang giữ khóa độc quyền trên Lượt thi 6
-- Thiết lập lock_timeout = '3s' để quan sát rõ hiện tượng cạnh tranh khóa
-- ---------------------------------------------------------------------
SET lock_timeout = '3s';

BEGIN;

SELECT ma_luot_thi, trang_thai 
FROM luot_thi 
WHERE ma_luot_thi = 6 
FOR UPDATE;

-- KẾT QUẢ MONG ĐỢI TRÊN MÀN HÌNH (Khớp 100% Hình 7.8 trang 124):
-- ERROR: canceling statement due to lock timeout
-- SQL state: 55P03

-- Đóng giao dịch lỗi sau khi timeout
ROLLBACK;
RESET lock_timeout;


-- ---------------------------------------------------------------------
-- THAO TÁC B2: Nộp bài chính thức sau khi Phiên A đã giải phóng khóa
-- ---------------------------------------------------------------------
-- Khi Phiên A đã COMMIT, Phiên B có thể nộp bài và chốt kết quả thành công:
CALL sp_nop_bai_va_chot_diem(6);

-- Kiểm tra lại: Lượt thi 6 đã chuyển sang HOAN_TAT và có kết quả chính thức:
SELECT lt.ma_luot_thi, lt.trang_thai, lt.thoi_gian_nop, kq.tong_diem, kq.trang_thai_ket_qua
FROM luot_thi lt
LEFT JOIN ket_qua kq ON lt.ma_luot_thi = kq.ma_luot_thi
WHERE lt.ma_luot_thi = 6;
