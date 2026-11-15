-- =====================================================================
-- ĐỒ ÁN 12: CSDL NGÂN HÀNG CÂU HỎI & THI TRỰC TUYẾN CÓ QUẢN LÝ PHIÊN BẢN
-- Học phần: Cơ sở dữ liệu nâng cao - Trường Đại học Sài Gòn (SGU)
-- Nhóm 27: Nguyễn Mạnh Dũng (3123410050) - Khưu Minh Đức (3123410083)
-- File: 05_oql_queries.sql (Đặc tả 5 Truy vấn OQL, Kết quả mong đợi & Ánh xạ SQL/JPQL)
-- Phục vụ: Mục 6.6 Báo cáo Đồ án & Checklist trước buổi Demo
-- =====================================================================

-- =====================================================================
-- TRUY VẤN OQL 1: LỌC CÂU HỎI TRẮC NGHIỆM NHIỀU ĐÁP ÁN ĐỘ KHÓ 'KHO'
-- =====================================================================
/*
1. Cú pháp OQL (Object Query Language):
   SELECT qv.question_root.question_id,
          qv.version_number,
          qv.content,
          (SELECT opt.content 
           FROM qv.options AS opt 
           WHERE opt.is_correct = true) AS correct_options
   FROM MultipleChoiceQuestionVersions AS qv
   WHERE qv.difficulty = "KHO" 
     AND qv.status = "DA_CONG_BO";

2. Kết quả mong đợi (Expected Output):
   - Trả về câu hỏi #3 ("Các hiện tượng dị thường đọc nào có thể xuất hiện ở mức READ COMMITTED?")
   - Phiên bản: 1
   - Danh sách phương án đúng: ["Non-repeatable Read (Đọc không lặp lại)", "Phantom Read (Đọc bóng ma)"]

3. Ánh xạ JPQL (Java Persistence Query Language):
   SELECT qv.questionRoot.questionId, qv.versionNumber, qv.content, opt.content
   FROM MultipleChoiceQuestionVersion qv JOIN qv.options opt
   WHERE qv.difficulty = 'KHO' AND qv.status = 'DA_CONG_BO' AND opt.isCorrect = true

4. Ánh xạ SQL thực thi trên PostgreSQL:
*/
SELECT 
    ch.ma_cau_hoi,
    pb.so_phien_ban,
    pb.noi_dung,
    json_agg(pa.noi_dung_phuong_an ORDER BY pa.thu_tu) AS tap_phuong_an_dung
FROM cau_hoi ch
JOIN phien_ban_cau_hoi pb ON ch.ma_cau_hoi = pb.ma_cau_hoi
JOIN phuong_an pa ON pb.ma_phien_ban_ch = pa.ma_phien_ban_ch
WHERE ch.loai_cau_hoi = 'NHIEU_DAP_AN'
  AND pb.muc_do_kho = 'KHO'
  AND pb.trang_thai_phien_ban = 'DA_CONG_BO'
  AND pa.la_dap_an_dung = TRUE
GROUP BY ch.ma_cau_hoi, pb.ma_phien_ban_ch, pb.so_phien_ban, pb.noi_dung;


-- =====================================================================
-- TRUY VẤN OQL 2: TÁI HIỆN ĐỀ THI LỊCH SỬ CỦA MỘT LƯỢT THI (attempt_id = 1)
-- =====================================================================
/*
1. Cú pháp OQL (Object Query Language):
   SELECT att.attempt_id,
          att.student_name,
          att.exam_version.version_number AS exam_ver,
          item.question_order,
          item.used_question_version.content AS question_text,
          item.used_question_version.version_number AS question_ver,
          item.max_score,
          ans.selected_option_ids,
          ans.essay_content
   FROM ExamAttempts AS att,
        att.exam_version.items AS item,
        att.answers AS ans
   WHERE att.attempt_id = 1
     AND ans.exam_item = item
   ORDER BY item.question_order ASC;

2. Kết quả mong đợi (Expected Output):
   - Tái hiện đúng 4 câu hỏi của đề thi giữa kỳ (Phiên bản đề #1).
   - Dù câu hỏi #1 đã được sửa đổi nội dung và tạo phiên bản #2, lượt thi 1 vẫn hiển thị đúng phiên bản #1.
   - Thí sinh Khưu Minh Đức đạt 10.00 điểm.

3. Ánh xạ SQL thực thi trên PostgreSQL:
*/
SELECT 
    lt.ma_luot_thi,
    nd.ho_ten AS ho_ten_thi_sinh,
    dt.ten_de_thi,
    pbde.so_phien_ban AS phien_ban_de,
    chtd.thu_tu_cau_hoi,
    pbch.noi_dung AS noi_dung_cau_hoi,
    pbch.so_phien_ban AS phien_ban_cau_hoi_su_dung,
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
-- TRUY VẤN OQL 3: TRUY VẤN ĐA HÌNH CÂU TỰ LUẬN ĐANG CHỜ CHẤM THỦ CÔNG
-- =====================================================================
/*
1. Cú pháp OQL (Object Query Language):
   SELECT att.attempt_id,
          att.student_name,
          ans.answer_id,
          ans.essay_content,
          item.used_question_version.grading_guide
   FROM ExamAttempts AS att,
        att.answers AS ans,
        ans.exam_item AS item
   WHERE att.status = "CHO_CHAM"
     AND item.used_question_version IS OF (EssayQuestionVersion);

2. Kết quả mong đợi (Expected Output):
   - Lượt thi #5 (Khưu Minh Đức)
   - Trả về nội dung bài làm tự luận và hướng dẫn chấm của giảng viên.

3. Ánh xạ JPQL (Java Persistence Query Language):
   SELECT att.attemptId, att.studentName, ans.essayContent, 
          TREAT(item.usedQuestionVersion AS EssayQuestionVersion).gradingGuide
   FROM ExamAttempt att JOIN att.answers ans JOIN ans.examItem item
   WHERE att.status = 'CHO_CHAM' 
     AND TYPE(item.usedQuestionVersion) = EssayQuestionVersion

4. Ánh xạ SQL thực thi trên PostgreSQL:
*/
SELECT 
    lt.ma_luot_thi,
    nd.ho_ten AS ho_ten_thi_sinh,
    ctl.ma_cau_tra_loi,
    ctl.noi_dung_tu_luan,
    pbch.huong_dan_cham,
    ctc.trang_thai_cham
FROM luot_thi lt
JOIN nguoi_dung nd ON lt.ma_nguoi_dung = nd.ma_nguoi_dung
JOIN cau_tra_loi ctl ON lt.ma_luot_thi = ctl.ma_luot_thi
JOIN cau_hoi_trong_de chtd ON ctl.ma_chi_tiet_de = chtd.ma_chi_tiet_de
JOIN phien_ban_cau_hoi pbch ON chtd.ma_phien_ban_ch = pbch.ma_phien_ban_ch
JOIN cau_hoi ch ON pbch.ma_cau_hoi = ch.ma_cau_hoi
JOIN chi_tiet_cham ctc ON ctl.ma_cau_tra_loi = ctc.ma_cau_tra_loi
WHERE lt.trang_thai = 'CHO_CHAM'
  AND ch.loai_cau_hoi = 'TU_LUAN'
  AND ctc.trang_thai_cham = 'CHO_CHAM';


-- =====================================================================
-- TRUY VẤN OQL 4: THỐNG KÊ SỐ LƯỢNG THÍ SINH VÀ ĐIỂM TRUNG BÌNH THEO ĐỀ THI
-- =====================================================================
/*
1. Cú pháp OQL (Object Query Language):
   SELECT ev.exam_version_id,
          ev.version_number,
          COUNT(att) AS total_attempts,
          AVG(att.final_result.total_score) AS avg_score
   FROM ExamVersions AS ev,
        ExamAttempts AS att
   WHERE att.exam_version = ev 
     AND att.status = "HOAN_TAT"
   GROUP BY ev.exam_version_id, ev.version_number;

2. Kết quả mong đợi (Expected Output):
   - Phiên bản đề #1 (Đề giữa kỳ v1): 4 lượt thi hoàn tất, điểm trung bình = (10 + 5 + 7.5 + 7.5) / 4 = 7.50 đ.

3. Ánh xạ SQL thực thi trên PostgreSQL:
*/
SELECT 
    pbde.ma_phien_ban_de,
    dt.ten_de_thi,
    pbde.so_phien_ban,
    COUNT(kq.ma_ket_qua) AS tong_so_luot_hoan_tat,
    ROUND(AVG(kq.tong_diem), 2) AS diem_trung_binh,
    MIN(kq.tong_diem) AS diem_thap_nhat,
    MAX(kq.tong_diem) AS diem_cao_nhat
FROM phien_ban_de_thi pbde
JOIN de_thi dt ON pbde.ma_de_thi = dt.ma_de_thi
JOIN luot_thi lt ON pbde.ma_phien_ban_de = lt.ma_phien_ban_de
JOIN ket_qua kq ON lt.ma_luot_thi = kq.ma_luot_thi
WHERE lt.trang_thai = 'HOAN_TAT'
  AND kq.trang_thai_ket_qua = 'CHINH_THUC'
GROUP BY pbde.ma_phien_ban_de, dt.ten_de_thi, pbde.so_phien_ban;


-- =====================================================================
-- TRUY VẤN OQL 5: ĐIỀU HƯỚNG CÂU HỎI THEO CHỦ ĐỀ VÀ MÔN HỌC
-- =====================================================================
/*
1. Cú pháp OQL (Object Query Language):
   SELECT q.topic_name,
          q.question_id,
          qv.version_number,
          qv.content,
          qv.difficulty
   FROM Questions AS q,
        q.has_versions AS qv
   WHERE q.question_type = "MOT_DAP_AN"
     AND qv.status = "DA_CONG_BO"
   ORDER BY q.topic_name ASC, q.question_id ASC;

2. Kết quả mong đợi (Expected Output):
   - Danh sách các câu hỏi một đáp án thuộc các chủ đề "Chỉ mục và tối ưu truy vấn", "Chuẩn hóa dữ liệu".

3. Ánh xạ SQL thực thi trên PostgreSQL:
*/
SELECT 
    mh.ten_mon_hoc,
    cd.ten_chu_de,
    ch.ma_cau_hoi,
    pb.so_phien_ban,
    pb.muc_do_kho,
    pb.noi_dung
FROM mon_hoc mh
JOIN chu_de cd ON mh.ma_mon_hoc = cd.ma_mon_hoc
JOIN cau_hoi ch ON cd.ma_chu_de = ch.ma_chu_de
JOIN phien_ban_cau_hoi pb ON ch.ma_cau_hoi = pb.ma_cau_hoi
WHERE ch.loai_cau_hoi = 'MOT_DAP_AN'
  AND pb.trang_thai_phien_ban = 'DA_CONG_BO'
ORDER BY cd.ten_chu_de ASC, ch.ma_cau_hoi ASC, pb.so_phien_ban DESC;
