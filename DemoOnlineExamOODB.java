// =====================================================================
// Đồ án 12: CSDL ngân hàng câu hỏi & thi trực tuyến có quản lý phiên bản
// Học phần: Cơ sở dữ liệu nâng cao - Trường Đại học Sài Gòn (SGU)
// Nhóm thực hiện: Nhóm 27
// File: DemoOnlineExamOODB.java (Chương 6 - Phân hệ Hướng đối tượng & Chấm điểm đa hình)
// Yêu cầu: Java 17+ hoặc Java 21+ (Chạy trực tiếp: java DemoOnlineExamOODB.java)
// =====================================================================

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

public class DemoOnlineExamOODB {

    // -----------------------------------------------------------------
    // 1. CÁC ENUM ĐẶC TẢ
    // -----------------------------------------------------------------
    public enum QuestionType { MOT_DAP_AN, NHIEU_DAP_AN, TU_LUAN }
    public enum Difficulty { DE, TRUNG_BINH, KHO }
    public enum VersionStatus { BAN_NHAP, DA_CONG_BO }
    public enum AttemptStatus { DANG_LAM, DA_NOP, CHO_CHAM, HOAN_TAT }

    // -----------------------------------------------------------------
    // 2. LỚP OPTION (PHƯƠNG ÁN TRẮC NGHIỆM)
    // -----------------------------------------------------------------
    public static class Option {
        private long optionId;
        private String content;
        private int orderNum;
        private boolean isCorrect;

        public Option(long optionId, String content, int orderNum, boolean isCorrect) {
            this.optionId = optionId;
            this.content = content;
            this.orderNum = orderNum;
            this.isCorrect = isCorrect;
        }

        public long getOptionId() { return optionId; }
        public String getContent() { return content; }
        public int getOrderNum() { return orderNum; }
        public boolean isCorrect() { return isCorrect; }

        @Override
        public String toString() {
            return String.format("[%d] %s %s", optionId, content, isCorrect ? "(ĐÚNG)" : "");
        }
    }

    // -----------------------------------------------------------------
    // 3. LỚP TRỪU TƯỢNG QUESTION VERSION (PHIÊN BẢN CÂU HỎI)
    // -----------------------------------------------------------------
    public static abstract class QuestionVersion {
        protected long versionId;
        protected int versionNumber;
        protected String content;
        protected Difficulty difficulty;
        protected VersionStatus status;
        protected LocalDateTime createdAt;
        protected Question questionRoot;

        public QuestionVersion(long versionId, int versionNumber, String content,
                               Difficulty difficulty, VersionStatus status, Question questionRoot) {
            this.versionId = versionId;
            this.versionNumber = versionNumber;
            this.content = content;
            this.difficulty = difficulty;
            this.status = status;
            this.createdAt = LocalDateTime.now();
            this.questionRoot = questionRoot;
        }

        public long getVersionId() { return versionId; }
        public int getVersionNumber() { return versionNumber; }
        public String getContent() { return content; }
        public Difficulty getDifficulty() { return difficulty; }
        public VersionStatus getStatus() { return status; }
        public Question getQuestionRoot() { return questionRoot; }

        // Phương thức trừu tượng chấm điểm đa hình (Polymorphic Method)
        public abstract float grade(Answer studentAnswer, float maxScore);
    }

    // -----------------------------------------------------------------
    // 4. LỚP CON 1: CÂU HỎI TRẮC NGHIỆM 1 ĐÁP ÁN ĐÚNG
    // -----------------------------------------------------------------
    public static class SingleChoiceQuestionVersion extends QuestionVersion {
        private Set<Option> options = new LinkedHashSet<>();

        public SingleChoiceQuestionVersion(long versionId, int versionNumber, String content,
                                           Difficulty difficulty, VersionStatus status, Question questionRoot) {
            super(versionId, versionNumber, content, difficulty, status, questionRoot);
        }

        public void addOption(Option opt) { options.add(opt); }
        public Set<Option> getOptions() { return options; }

        @Override
        public float grade(Answer studentAnswer, float maxScore) {
            if (studentAnswer == null || studentAnswer.getSelectedOptionIds().isEmpty()) {
                return 0.0f;
            }
            // Chỉ được phép chọn đúng 1 đáp án
            if (studentAnswer.getSelectedOptionIds().size() > 1) {
                return 0.0f;
            }
            Long selectedId = studentAnswer.getSelectedOptionIds().iterator().next();
            for (Option opt : options) {
                if (opt.getOptionId() == selectedId && opt.isCorrect()) {
                    return maxScore;
                }
            }
            return 0.0f;
        }
    }

    // -----------------------------------------------------------------
    // 5. LỚP CON 2: CÂU HỎI TRẮC NGHIỆM NHIỀU ĐÁP ÁN ĐÚNG (TOÀN PHẦN)
    // -----------------------------------------------------------------
    public static class MultipleChoiceQuestionVersion extends QuestionVersion {
        private Set<Option> options = new LinkedHashSet<>();

        public MultipleChoiceQuestionVersion(long versionId, int versionNumber, String content,
                                             Difficulty difficulty, VersionStatus status, Question questionRoot) {
            super(versionId, versionNumber, content, difficulty, status, questionRoot);
        }

        public void addOption(Option opt) { options.add(opt); }
        public Set<Option> getOptions() { return options; }

        @Override
        public float grade(Answer studentAnswer, float maxScore) {
            if (studentAnswer == null || studentAnswer.getSelectedOptionIds().isEmpty()) {
                return 0.0f;
            }

            Set<Long> correctIds = options.stream()
                    .filter(Option::isCorrect)
                    .map(Option::getOptionId)
                    .collect(Collectors.toSet());

            Set<Long> selectedIds = studentAnswer.getSelectedOptionIds();

            // Quy tắc TOÀN PHẦN (All-or-Nothing): Tập lựa chọn phải trùng khớp tuyệt đối tập đáp án đúng
            if (selectedIds.equals(correctIds)) {
                return maxScore;
            }
            return 0.0f;
        }
    }

    // -----------------------------------------------------------------
    // 6. LỚP CON 3: CÂU HỎI TỰ LUẬN (CHẤM THỦ CÔNG)
    // -----------------------------------------------------------------
    public static class EssayQuestionVersion extends QuestionVersion {
        private String gradingGuide;

        public EssayQuestionVersion(long versionId, int versionNumber, String content,
                                    Difficulty difficulty, VersionStatus status, Question questionRoot,
                                    String gradingGuide) {
            super(versionId, versionNumber, content, difficulty, status, questionRoot);
            this.gradingGuide = gradingGuide;
        }

        public String getGradingGuide() { return gradingGuide; }

        @Override
        public float grade(Answer studentAnswer, float maxScore) {
            // Trả về -1.0f để biểu thị bài thi cần chuyển sang trạng thái chờ chấm thủ công
            return -1.0f;
        }
    }

    // -----------------------------------------------------------------
    // 7. LỚP QUESTION (CÂU HỎI GỐC)
    // -----------------------------------------------------------------
    public static class Question {
        private long questionId;
        private String topic;
        private QuestionType type;
        private List<QuestionVersion> versions = new ArrayList<>();

        public Question(long questionId, String topic, QuestionType type) {
            this.questionId = questionId;
            this.topic = topic;
            this.type = type;
        }

        public long getQuestionId() { return questionId; }
        public String getTopic() { return topic; }
        public QuestionType getType() { return type; }
        public List<QuestionVersion> getVersions() { return versions; }

        public void addVersion(QuestionVersion version) {
            this.versions.add(version);
        }
    }

    // -----------------------------------------------------------------
    // 8. CẤU TRÚC ĐỀ THI: EXAM, EXAM VERSION, EXAM ITEM
    // -----------------------------------------------------------------
    public static class ExamItem {
        private long itemId;
        private int questionOrder;
        private float maxScore;
        private QuestionVersion questionVersion;

        public ExamItem(long itemId, int questionOrder, float maxScore, QuestionVersion questionVersion) {
            this.itemId = itemId;
            this.questionOrder = questionOrder;
            this.maxScore = maxScore;
            this.questionVersion = questionVersion;
        }

        public long getItemId() { return itemId; }
        public int getQuestionOrder() { return questionOrder; }
        public float getMaxScore() { return maxScore; }
        public QuestionVersion getQuestionVersion() { return questionVersion; }
    }

    public static class ExamVersion {
        private long examVersionId;
        private int versionNumber;
        private int durationMinutes;
        private List<ExamItem> items = new ArrayList<>();

        public ExamVersion(long examVersionId, int versionNumber, int durationMinutes) {
            this.examVersionId = examVersionId;
            this.versionNumber = versionNumber;
            this.durationMinutes = durationMinutes;
        }

        public void addItem(ExamItem item) { items.add(item); }
        public List<ExamItem> getItems() { return items; }
        public int getVersionNumber() { return versionNumber; }
    }

    // -----------------------------------------------------------------
    // 9. LƯỢT THI & BÀI LÀM: EXAM ATTEMPT, ANSWER
    // -----------------------------------------------------------------
    public static class Answer {
        private long answerId;
        private ExamItem examItem;
        private Set<Long> selectedOptionIds = new HashSet<>();
        private String essayContent;

        public Answer(long answerId, ExamItem examItem) {
            this.answerId = answerId;
            this.examItem = examItem;
        }

        public long getAnswerId() { return answerId; }
        public ExamItem getExamItem() { return examItem; }
        public Set<Long> getSelectedOptionIds() { return selectedOptionIds; }
        public String getEssayContent() { return essayContent; }

        public void selectOption(long optionId) { selectedOptionIds.add(optionId); }
        public void setEssayContent(String content) { this.essayContent = content; }
    }

    public static class ExamAttempt {
        private long attemptId;
        private String studentName;
        private ExamVersion examVersion;
        private AttemptStatus status;
        private Map<Long, Answer> answers = new LinkedHashMap<>();
        private Float totalScore = null;

        public ExamAttempt(long attemptId, String studentName, ExamVersion examVersion) {
            this.attemptId = attemptId;
            this.studentName = studentName;
            this.examVersion = examVersion;
            this.status = AttemptStatus.DANG_LAM;
        }

        public void recordAnswer(Answer ans) {
            answers.put(ans.getExamItem().getItemId(), ans);
        }

        public long getAttemptId() { return attemptId; }
        public String getStudentName() { return studentName; }
        public ExamVersion getExamVersion() { return examVersion; }
        public AttemptStatus getStatus() { return status; }
        public Map<Long, Answer> getAnswers() { return answers; }
        public Float getTotalScore() { return totalScore; }
        public void setTotalScore(Float score) { this.totalScore = score; }
        public void setStatus(AttemptStatus st) { this.status = st; }

        // Nghiệp vụ nộp bài & chấm điểm đa hình
        public void submitAndGrade() {
            System.out.println("\n-----------------------------------------------------------");
            System.out.printf(">> TIẾN HÀNH NỘP BÀI VÀ CHẤM ĐIỂM CHO LƯỢT THI #%d (%s)\n", attemptId, studentName);
            System.out.println("-----------------------------------------------------------");

            float sumScore = 0.0f;
            boolean hasEssay = false;

            for (ExamItem item : examVersion.getItems()) {
                Answer ans = answers.get(item.getItemId());
                QuestionVersion qv = item.getQuestionVersion();

                // GỌI PHƯƠNG THỨC CHẤM ĐA HÌNH
                float score = qv.grade(ans, item.getMaxScore());

                if (score < 0) {
                    hasEssay = true;
                    System.out.printf(" - Câu %d [Tự luận] (Mã PB #%d): Chờ giảng viên chấm thủ công.\n",
                            item.getQuestionOrder(), qv.getVersionId());
                } else {
                    sumScore += score;
                    System.out.printf(" - Câu %d [%s] (Mã PB #%d, Tối đa %.2f đ): Đạt được %.2f đ\n",
                            item.getQuestionOrder(),
                            (qv instanceof SingleChoiceQuestionVersion) ? "Một đáp án" : "Nhiều đáp án",
                            qv.getVersionId(), item.getMaxScore(), score);
                }
            }

            if (hasEssay) {
                this.status = AttemptStatus.CHO_CHAM;
                System.out.printf("=> KẾT QUẢ TẠM THỜI: Trạng thái = CHO_CHAM (Điểm trắc nghiệm đạt: %.2f đ)\n", sumScore);
            } else {
                this.status = AttemptStatus.HOAN_TAT;
                this.totalScore = sumScore;
                System.out.printf("=> KẾT QUẢ CHÍNH THỨC: Trạng thái = HOAN_TAT | TỔNG ĐIỂM = %.2f đ\n", sumScore);
            }
        }
    }

    // -----------------------------------------------------------------
    // 10. HÀM MAIN: DỰNG DỮ LIỆU THỬ NGHIỆM VÀ CHẠY MÔ PHỎNG OODB/OQL
    // -----------------------------------------------------------------
    public static void main(String[] args) {
        System.out.println("===========================================================");
        System.out.println("ĐỒ ÁN 12 - HỌC PHẦN: CƠ SỞ DỮ LIỆU NÂNG CAO");
        System.out.println("CHƯƠNG 6: THỰC THI MÔ HÌNH HƯỚNG ĐỐI TƯỢNG VÀ CHẤM ĐIỂM ĐA HÌNH");
        System.out.println("Nhóm 27 - Đề tài: Ngân hàng câu hỏi có quản lý phiên bản");
        System.out.println("===========================================================");

        // BƯỚC 1: KHỞI TẠO CÁC CÂU HỎI VÀ PHIÊN BẢN CÂU HỎI
        // Câu 1: Trắc nghiệm 1 đáp án (Bất biến phiên bản 1)
        Question q1 = new Question(1, "PostgreSQL Indexing", QuestionType.MOT_DAP_AN);
        SingleChoiceQuestionVersion q1_v1 = new SingleChoiceQuestionVersion(101, 1,
                "Chỉ mục B-Tree trong CSDL phù hợp nhất cho loại truy vấn nào?",
                Difficulty.DE, VersionStatus.DA_CONG_BO, q1);
        q1_v1.addOption(new Option(1, "Truy vấn so sánh bằng và khoảng giá trị (=, <, BETWEEN)", 1, true));
        q1_v1.addOption(new Option(2, "Truy vấn tìm kiếm toàn văn Full-Text Search", 2, false));
        q1_v1.addOption(new Option(3, "Truy vấn dữ liệu hình học đa chiều", 3, false));
        q1.addVersion(q1_v1);

        // Giả sử sau này Câu 1 phát sinh phiên bản 2 (sửa từ ngữ câu hỏi)
        SingleChoiceQuestionVersion q1_v2 = new SingleChoiceQuestionVersion(102, 2,
                "Chỉ mục B-Tree trong hệ quản trị PostgreSQL tối ưu cho toán tử nào sau đây?",
                Difficulty.DE, VersionStatus.DA_CONG_BO, q1);
        q1_v2.addOption(new Option(4, "Toán tử =, <, <=, >, >= và BETWEEN", 1, true));
        q1_v2.addOption(new Option(5, "Toán tử tìm kiếm từ khóa không phân biệt hoa thường", 2, false));
        q1.addVersion(q1_v2);

        // Câu 2: Trắc nghiệm nhiều đáp án (Quy tắc chấm toàn phần TOAN_PHAN)
        Question q2 = new Question(2, "Transaction & Concurrency", QuestionType.NHIEU_DAP_AN);
        MultipleChoiceQuestionVersion q2_v1 = new MultipleChoiceQuestionVersion(201, 1,
                "Các hiện tượng dị thường đọc nào có thể xuất hiện ở mức READ COMMITTED?",
                Difficulty.KHO, VersionStatus.DA_CONG_BO, q2);
        q2_v1.addOption(new Option(10, "Dirty Read (Đọc rác)", 1, false));
        q2_v1.addOption(new Option(11, "Non-repeatable Read (Đọc không lặp lại)", 2, true));
        q2_v1.addOption(new Option(12, "Phantom Read (Đọc bóng ma)", 3, true));
        q2.addVersion(q2_v1);

        // Câu 3: Tự luận
        Question q3 = new Question(3, "Transaction Locking", QuestionType.TU_LUAN);
        EssayQuestionVersion q3_v1 = new EssayQuestionVersion(301, 1,
                "Trình bày cơ chế hoạt động của lệnh SELECT ... FOR UPDATE trong PostgreSQL.",
                Difficulty.TRUNG_BINH, VersionStatus.DA_CONG_BO, q3,
                "Đáp án yêu cầu: Nêu cơ chế khóa hàng độc quyền, giải quyết xung đột concurrent submit.");
        q3.addVersion(q3_v1);

        // BƯỚC 2: TẠO ĐỀ THI VÀ PHIÊN BẢN ĐỀ THI THAM CHIẾU ĐÚNG PHIÊN BẢN CÂU HỎI
        ExamVersion examVer1 = new ExamVersion(1001, 1, 45);
        examVer1.addItem(new ExamItem(1, 1, 3.0f, q1_v1)); // Tham chiếu q1_v1 (phiên bản 1)
        examVer1.addItem(new ExamItem(2, 2, 3.0f, q2_v1)); // Tham chiếu q2_v1
        examVer1.addItem(new ExamItem(3, 3, 4.0f, q3_v1)); // Tham chiếu q3_v1

        // BƯỚC 3: MÔ PHỎNG LƯỢT THI CỦA THÍ SINH
        // Thí sinh 1: Nguyễn Mạnh Dũng (Làm đúng câu 1, đúng câu 2 toàn phần, câu 3 tự luận)
        ExamAttempt attempt1 = new ExamAttempt(1, "Nguyễn Mạnh Dũng - 3123410050", examVer1);
        Answer ans1 = new Answer(1, examVer1.getItems().get(0));
        ans1.selectOption(1); // Chọn đúng
        attempt1.recordAnswer(ans1);

        Answer ans2 = new Answer(2, examVer1.getItems().get(1));
        ans2.selectOption(11);
        ans2.selectOption(12); // Chọn đúng đủ cả 2 phương án đúng
        attempt1.recordAnswer(ans2);

        Answer ans3 = new Answer(3, examVer1.getItems().get(2));
        ans3.setEssayContent("Lệnh SELECT FOR UPDATE đặt khóa độc quyền trên dòng được chọn...");
        attempt1.recordAnswer(ans3);

        // Nộp bài thí sinh 1
        attempt1.submitAndGrade();

        // Thí sinh 2: Khưu Minh Đức (Làm đúng câu 1, nhưng câu 2 CHỌN THIẾU -> 0 điểm do quy tắc TOAN_PHAN)
        ExamAttempt attempt2 = new ExamAttempt(2, "Khưu Minh Đức - 3123410083", examVer1);
        Answer ans2_1 = new Answer(4, examVer1.getItems().get(0));
        ans2_1.selectOption(1); // Đúng
        attempt2.recordAnswer(ans2_1);

        Answer ans2_2 = new Answer(5, examVer1.getItems().get(1));
        ans2_2.selectOption(11); // Chỉ chọn 1 ý đúng (thiếu ý 12) -> Phải nhận 0đ
        attempt2.recordAnswer(ans2_2);

        Answer ans2_3 = new Answer(6, examVer1.getItems().get(2));
        ans2_3.setEssayContent("SELECT FOR UPDATE khóa dòng dữ liệu.");
        attempt2.recordAnswer(ans2_3);

        // Nộp bài thí sinh 2
        attempt2.submitAndGrade();

        // BƯỚC 4: MÔ PHỎNG TRUY VẤN OQL TÁI HIỆN ĐỀ THI LỊCH SỬ (OQL 2)
        System.out.println("\n===========================================================");
        System.out.println("MÔ PHỎNG THỰC THI TRUY VẤN OQL TÁI HIỆN ĐỀ LỊCH SỬ (OQL 2)");
        System.out.println("Lượt thi #1 của Nguyễn Mạnh Dũng (Dù ngân hàng đề đã có Câu 1 phiên bản 2)");
        System.out.println("===========================================================");
        for (ExamItem item : attempt1.getExamVersion().getItems()) {
            QuestionVersion qv = item.getQuestionVersion();
            System.out.printf("Vị trí câu %d: %s\n", item.getQuestionOrder(), qv.getContent());
            System.out.printf("  -> Mã phiên bản sử dụng: #%d (Phiên bản số: %d)\n", qv.getVersionId(), qv.getVersionNumber());
            if (qv instanceof SingleChoiceQuestionVersion sc) {
                for (Option o : sc.getOptions()) {
                    System.out.printf("     [ ] %s\n", o);
                }
            } else if (qv instanceof MultipleChoiceQuestionVersion mc) {
                for (Option o : mc.getOptions()) {
                    System.out.printf("     [ ] %s\n", o);
                }
            }
        }
        System.out.println("\n[KẾT LUẬN]: Đề thi lịch sử được tái hiện chính xác 100% phiên bản gốc!");
        System.out.println("===========================================================");
    }
}
