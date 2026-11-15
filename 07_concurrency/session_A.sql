-- =====================================================================
-- BƯỚC 4: THỰC NGHIỆM ĐỒNG THỜI (CONCURRENCY) - CỬA SỔ QUERY TOOL A
-- Đồ án 12: CSDL ngân hàng câu hỏi & thi trực tuyến có quản lý phiên bản
-- Khớp 100% với Mục 7.4 & 7.5 trong Báo cáo CSDLNC.pdf (Hình 7.7, Hình 7.8, Hình 7.10)
-- Đối tượng thử nghiệm: Lượt thi số 6 (Lê Hoàng Nam - Đang làm bài DANG_LAM)
-- =====================================================================

-- ---------------------------------------------------------------------
-- PHẦN 1: DEMO KHÓA BI QUAN ĐỒNG THỜI (Khớp Hình 7.7 & 7.8 Báo cáo)
-- ---------------------------------------------------------------------

-- Thao tác A1: Khởi tạo giao dịch tại Phiên A và đặt khóa độc quyền trên Lượt thi 6
BEGIN;

SELECT ma_luot_thi, trang_thai 
FROM luot_thi 
WHERE ma_luot_thi = 6 
FOR UPDATE;

-- >>> DỪNG LẠI Ở ĐÂY VÀ GIỮ NGUYÊN GIAO DỊCH A (CHƯA COMMIT) <<<
-- Chuyển sang CỬA SỔ B (session_B.sql) và chạy lệnh thử lấy khóa trên cùng lượt thi 6.
-- Bạn sẽ thấy Phiên B bị chặn và báo lỗi Lock Timeout (Mã lỗi 55P03 sau 3 giây).


-- Thao tác A2: Sau khi Phiên B đã ghi nhận kết quả cạnh tranh khóa, kết thúc giao dịch A
COMMIT;


-- ---------------------------------------------------------------------
-- PHẦN 2: DEMO AUTOSAVE BỊ CHẶN GHI ĐÈ BÀI ĐÃ NỘP (Khớp Hình 7.10 Báo cáo)
-- ---------------------------------------------------------------------
-- Thí sinh có Lượt thi số 1 đã ở trạng thái HOAN_TAT.
-- Tiến trình Autosave gửi lệnh cập nhật câu trả lời số 1 đến sau:
UPDATE cau_tra_loi 
SET lan_cap_nhat = lan_cap_nhat + 1,
    thoi_gian_cap_nhat = now()
WHERE ma_cau_tra_loi = 1;

-- KẾT QUẢ MONG ĐỢI TRÊN MÀN HÌNH (Khớp 100% Hình 7.10 trang 128):
-- ERROR: Lượt thi (Mã = 1) đã ở trạng thái HOAN_TAT, không được phép lưu hoặc ghi đè câu trả lời!
-- CONTEXT: PL/pgSQL function fn_trg_kiem_soat_cau_tra_loi() line 15 at RAISE
