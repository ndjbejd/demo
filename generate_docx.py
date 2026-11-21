# -*- coding: utf-8 -*-
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def create_document():
    doc = docx.Document()

    # Page setup: Standard A4, 2cm margins
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)

    def format_cell_box(cell, bg_color='F8FAFC', border_color='0284C7'):
        tcPr = cell._tc.get_or_add_tcPr()
        shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{bg_color}"/>')
        tcPr.append(shd)
        borders = parse_xml(f'''
            <w:tcBorders {nsdecls("w")}>
                <w:top w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>
                <w:left w:val="single" w:sz="24" w:space="0" w:color="{border_color}"/>
                <w:bottom w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>
                <w:right w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>
            </w:tcBorders>
        ''')
        tcPr.append(borders)

    def add_placeholder(doc, title, desc):
        tbl = doc.add_table(rows=1, cols=1)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        tbl.autofit = False
        tbl.columns[0].width = Inches(6.8)
        cell = tbl.cell(0, 0)
        format_cell_box(cell, bg_color='F8FAFC', border_color='0284C7')
        p = cell.paragraphs[0]
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(6)
        
        run1 = p.add_run(f'📷 [KHUNG CHÈN ẢNH: {title}]\n')
        run1.bold = True
        run1.font.color.rgb = RGBColor(2, 132, 199)
        run1.font.size = Pt(11)
        
        run2 = p.add_run(f'Mục đích minh họa: {desc}\n👉 Nhấp chuột vào đây, nhấn phím Enter để xuống dòng rồi nhấn Ctrl + V để dán ảnh chụp màn hình vào ô này.\n')
        run2.italic = True
        run2.font.color.rgb = RGBColor(100, 116, 139)
        run2.font.size = Pt(9.5)

        p_cap = doc.add_paragraph()
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_cap.paragraph_format.space_before = Pt(3)
        p_cap.paragraph_format.space_after = Pt(12)
        rcap = p_cap.add_run(f'Hình minh chứng: {title}')
        rcap.italic = True
        rcap.font.size = Pt(9.5)
        rcap.font.color.rgb = RGBColor(71, 85, 105)

    # --- TITLE ---
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_after = Pt(4)
    r_sub = p_title.add_run('TRƯỜNG ĐẠI HỌC SÀI GÒN - KHOA CÔNG NGHỆ THÔNG TIN\nHỌC PHẦN: CƠ SỞ DỮ LIỆU NÂNG CAO\n')
    r_sub.font.size = Pt(11)
    r_sub.font.color.rgb = RGBColor(71, 85, 105)

    r_main = p_title.add_run('TÀI LIỆU HƯỚNG DẪN & KỊCH BẢN LIVE DEMO CHƯƠNG 6\n')
    r_main.bold = True
    r_main.font.size = Pt(16)
    r_main.font.color.rgb = RGBColor(30, 58, 138)

    r_topic = p_title.add_run('Đề tài: Ngân hàng câu hỏi và tổ chức thi trực tuyến có quản lý phiên bản\nNhóm 27 - Phân hệ chuyên sâu: Quản lý phiên bản bất biến, OODBMS & Kiểm soát giao dịch đồng thời')
    r_topic.italic = True
    r_topic.font.size = Pt(10.5)
    r_topic.font.color.rgb = RGBColor(51, 65, 85)

    doc.add_paragraph().paragraph_format.space_after = Pt(8)

    # --- PHẦN 1 ---
    h1 = doc.add_heading('PHẦN 1: HƯỚNG DẪN MỞ VÀ CHẠY FILE SQL TRÊN PGADMIN 4', level=1)
    h1.style.font.color.rgb = RGBColor(30, 58, 138)

    p1 = doc.add_paragraph()
    p1.add_run('Để buổi demo diễn ra thành công và chuyên nghiệp, bạn thực hiện theo các bước sau:\n')
    p1.add_run('1. Kết nối cơ sở dữ liệu: ').bold = True
    p1.add_run('Ở cột Object Explorer bên trái, mở Servers > PostgreSQL 17, nhập mật khẩu kết nối.\n')
    p1.add_run('2. Mở cửa sổ Query Tool: ').bold = True
    p1.add_run('Click chuột phải vào Database (ví dụ postgres hoặc csdlnc) > Chọn Query Tool (biểu tượng tia sét/phễu lọc).\n')
    p1.add_run('3. Mở mã nguồn SQL: ').bold = True
    p1.add_run('Bấm vào biểu tượng Folder (Open File 📂) trên thanh công cụ của Query Tool, duyệt đến thư mục D:\\CSDLNC\\Demo final\\ và chọn file cần chạy (hoặc mở file bằng Notepad, bấm Ctrl+A > Ctrl+C rồi sang Query Tool bấm Ctrl+V dán vào).\n')
    p1.add_run('4. Thực thi từng đoạn lệnh: ').bold = True
    p1.add_run('Dùng chuột bôi đen chính xác đoạn lệnh cần demo, sau đó nhấn phím F5 (Execute). Tuyệt đối không bấm F5 khi chưa bôi đen để tránh việc lỗi cố ý của bước này làm dừng các bước sau.')

    add_placeholder(doc, 'Giao diện Query Tool pgAdmin 4 và thanh công cụ', 'Ảnh chụp cửa sổ pgAdmin 4 với Query Tool đang mở, nút Open File và nút Execute F5')

    # --- PHẦN 2 ---
    h2 = doc.add_heading('PHẦN 2: CHUẨN BỊ MÔI TRƯỜNG TRƯỚC BUỔI DEMO', level=1)
    h2.style.font.color.rgb = RGBColor(30, 58, 138)

    p2 = doc.add_paragraph()
    p2.add_run('Trước khi bắt đầu buổi demo, hãy mở sẵn sàng các tệp sau trên pgAdmin 4:\n')
    p2.add_run('• Bước khởi tạo (Chạy 1 lần): ').bold = True
    p2.add_run('Chạy toàn bộ file 01_schema-v2.sql để tạo 17 bảng và dữ liệu mẫu. Sau đó chạy file 04_transactions.sql để cài đặt các Stored Procedures nộp bài và lưu bài.\n')
    p2.add_run('• Mở sẵn 3 Tab Query Tool trên pgAdmin:\n').bold = True
    p2.add_run('   - Tab 1: Mở sẵn file 06_demo.sql (Dùng cho Bước 3, Bước 5 và Bước 6).\n')
    p2.add_run('   - Tab 2: Mở sẵn file 07_concurrency/session_A.sql (Cửa sổ A dùng cho Bước 4).\n')
    p2.add_run('   - Tab 3: Mở sẵn file 07_concurrency/session_B.sql (Cửa sổ B dùng cho Bước 4).\n')

    add_placeholder(doc, 'Trạng thái sẵn sàng 3 Tab Query Tool trên pgAdmin 4', 'Ảnh chụp 3 tab Query Tool mở song song trên pgAdmin chuẩn bị cho các bước demo')

    # --- PHẦN 3 ---
    h3 = doc.add_heading('PHẦN 3: KỊCH BẢN CHI TIẾT TỪ BƯỚC 3 ĐẾN BƯỚC 6 (5 PHÚT DEMO)', level=1)
    h3.style.font.color.rgb = RGBColor(30, 58, 138)

    # BƯỚC 3
    h_b3 = doc.add_heading('3.1. BƯỚC 3: TÁI HIỆN ĐỀ THI LỊCH SỬ (Thời lượng: ~50 giây)', level=2)
    h_b3.style.font.color.rgb = RGBColor(2, 132, 199)

    p_b3 = doc.add_paragraph()
    p_b3.add_run('• Mục tiêu chứng minh: ').bold = True
    p_b3.add_run('Yêu cầu 1 của Giảng viên - Đề thi đã thi trong quá khứ không bị thay đổi nội dung, phương án và kết quả chấm dù ngân hàng câu hỏi đã được sửa đổi và phát hành phiên bản mới.\n')
    p_b3.add_run('• Thao tác trên pgAdmin: ').bold = True
    p_b3.add_run('Tại Tab 1 (06_demo.sql), dùng chuột bôi đen các câu lệnh ở Mục 3.3 & 3.4 rồi nhấn phím F5.\n')
    p_b3.add_run('• Lời thoại thuyết trình trước Thầy:\n').bold = True
    
    r_say3 = p_b3.add_run(
        '\"Kính thưa thầy, em xin đại diện nhóm trình bày phần chuyên sâu Chương 6. Vấn đề cốt lõi đầu tiên là bảo toàn tính bất biến của đề thi lịch sử.\n\n'
        'Như thầy thấy trên kết quả truy vấn: Câu hỏi số 1 ban đầu ở Phiên bản 1, sau kỳ thi đã được giảng viên chỉnh sửa nội dung và tạo thành Phiên bản số 2 (Mã PB #2). '
        'Tuy nhiên, khi hệ thống truy vấn lại Lượt thi số 1 của thí sinh Khưu Minh Đức đã thi ở học kỳ trước, nhờ cơ chế tham chiếu phiên bản bất biến, đề thi vẫn kết nối chính xác với Phiên bản số 1 (Mã PB #1). '
        'Nội dung câu hỏi, tập phương án và điểm số 10.00 của bài thi lịch sử được bảo toàn nguyên vẹn 100%, đáp ứng trọn vẹn yêu cầu kiểm định và phúc khảo học vụ ạ!\"\n'
    )
    r_say3.font.color.rgb = RGBColor(15, 23, 42)
    r_say3.italic = True

    add_placeholder(doc, 'Kết quả tái hiện đề thi lịch sử của Lượt thi số 1 (Khớp Hình 7.2 & 7.5 Báo cáo)', 'Ảnh chụp màn hình kết quả pgAdmin cho thấy câu hỏi 1 hiển thị đúng phiên bản số 1 kèm điểm tối đa 10.00')

    # BƯỚC 4
    h_b4 = doc.add_heading('3.2. BƯỚC 4: AUTOSAVE VÀ SUBMIT ĐỒNG THỜI (Thời lượng: ~1 phút 30 giây)', level=2)
    h_b4.style.font.color.rgb = RGBColor(2, 132, 199)

    p_b4 = doc.add_paragraph()
    p_b4.add_run('• Mục tiêu chứng minh: ').bold = True
    p_b4.add_run('Yêu cầu 2 của Giảng viên - Kiểm soát tương tranh: Giao dịch nộp bài khóa bi quan bằng SELECT ... FOR UPDATE ngăn chặn xung đột, và chức năng Autosave đến sau tuyệt đối không thể ghi đè câu trả lời của bài đã nộp.\n')
    p_b4.add_run('• Thao tác trên pgAdmin:\n').bold = True
    p_b4.add_run('   1. Tại Tab 2 (session_A.sql): Bôi đen khối THAO TÁC A1 > Bấm F5 (Bắt đầu lưu bài và giữ khóa độc quyền trên Lượt thi 6).\n')
    p_b4.add_run('   2. Chuyển ngay sang Tab 3 (session_B.sql): Bôi đen THAO TÁC B1 > Bấm F5. Chỉ cho thầy thấy Tab B đang ở trạng thái Executing query... (đang chờ giải phóng khóa do câu lệnh SELECT FOR UPDATE).\n')
    p_b4.add_run('   3. Quay lại Tab 2 (session_A.sql): Bôi đen chữ COMMIT; > Bấm F5. Lúc này Tab B bên kia sẽ hoàn tất ngay lập tức.\n')
    p_b4.add_run('   4. Vẫn tại Tab 2: Bôi đen khối THAO TÁC A3 (thử gửi lệnh Autosave ghi đè câu trả lời sau khi bài đã nộp) > Bấm F5.\n')
    p_b4.add_run('• Lời thoại thuyết trình trước Thầy:\n').bold = True
    
    r_say4 = p_b4.add_run(
        '\"Tiếp theo là bài toán xử lý tương tranh giữa Autosave và Nộp bài đồng thời.\n\n'
        'Em đang mô phỏng ở Cửa sổ A: Thí sinh đang lưu bài tự động và giữ khóa trên Lượt thi số 6. Cùng lúc đó tại Cửa sổ B, thí sinh bấm Nộp bài. '
        'Thầy quan sát thấy Cửa sổ B áp dụng cơ chế khóa bi quan SELECT ... FOR UPDATE, nên tiến trình nộp bài tự động dừng lại chờ Cửa sổ A hoàn tất mà không gây ra xung đột dữ liệu.\n\n'
        'Ngay khi Cửa sổ A Commit, Cửa sổ B lập tức nhận khóa và nộp bài thành công. '
        'Và đặc biệt, khi bài thi đã được nộp xong, nếu tiến trình Autosave chạy ngầm gửi câu trả lời lên sau, Trigger trg_kiem_soat_cau_tra_loi lập tức chặn đứng và ném lỗi từ chối như trên màn hình. '
        'Câu trả lời và điểm số đã nộp được bảo vệ tuyệt đối, không thể bị ghi đè ạ!\"\n'
    )
    r_say4.font.color.rgb = RGBColor(15, 23, 42)
    r_say4.italic = True

    add_placeholder(doc, 'Cạnh tranh khóa giữa 2 phiên và Trigger chặn Autosave ghi đè (Khớp Hình 7.8 & 7.10 Báo cáo)', 'Ảnh chụp màn hình Cửa sổ B chờ khóa timeout lỗi 55P03 và Trigger ném lỗi từ chối ghi đè bài đã nộp')

    # BƯỚC 5
    h_b5 = doc.add_heading('3.3. BƯỚC 5: NỘP BÀI LẶP VÀ CHỐNG CHẤM TRÙNG (Thời lượng: ~50 giây)', level=2)
    h_b5.style.font.color.rgb = RGBColor(2, 132, 199)

    p_b5 = doc.add_paragraph()
    p_b5.add_run('• Mục tiêu chứng minh: ').bold = True
    p_b5.add_run('Yêu cầu 3 của Giảng viên - Thí sinh nhấp nộp bài liên tiếp nhiều lần hoặc mở nhiều tab cùng nộp thì hệ thống chỉ ghi nhận đúng 1 kết quả chính thức duy nhất, điểm số không bị tính trùng lặp.\n')
    p_b5.add_run('• Thao tác trên pgAdmin: ').bold = True
    p_b5.add_run('Tại Tab 1 (06_demo.sql), bôi đen đoạn Mục 5.1, 5.2 và 5.3 > Nhấn F5.\n')
    p_b5.add_run('• Lời thoại thuyết trình trước Thầy:\n').bold = True
    
    r_say5 = p_b5.add_run(
        '\"Yêu cầu cốt lõi thứ ba là chống nộp bài lặp và chống ghi nhận kết quả trùng.\n\n'
        'Khi thí sinh bấm nút Nộp bài nhiều lần hoặc mở 2 tab cùng nộp:\n'
        'Thứ nhất, ở câu lệnh 5.1: Hệ thống kiểm tra điều kiện trạng thái DANG_LAM. Vì lượt thi đã chuyển sang hoàn tất, lệnh trả về kết quả UPDATE 0, loại trừ hoàn toàn việc đổi trạng thái lặp lại.\n'
        'Thứ hai, ở câu lệnh 5.3: Nếu cố tình chèn thêm kết quả lần hai, hệ thống lập tức từ chối và ném lỗi 23505 do vi phạm ràng buộc uq_ket_qua_luot_thi.\n'
        'Như bảng kiểm tra COUNT(*) chứng minh: Mỗi lượt thi chỉ có duy nhất một kết quả chính thức, điểm số không bao giờ bị tính trùng hay sai lệch ạ!\"\n'
    )
    r_say5.font.color.rgb = RGBColor(15, 23, 42)
    r_say5.italic = True

    add_placeholder(doc, 'Ngăn chuyển trạng thái lặp và Ràng buộc UNIQUE chống kết quả trùng (Khớp Hình 7.9 & 7.12 Báo cáo)', 'Ảnh chụp kết quả UPDATE 0 và thông báo lỗi 23505 vi phạm ràng buộc uq_ket_qua_luot_thi')

    # BƯỚC 6
    h_b6 = doc.add_heading('3.4. BƯỚC 6: KIỂM THỬ ROLLBACK GIAO DỊCH (Thời lượng: ~40 giây)', level=2)
    h_b6.style.font.color.rgb = RGBColor(2, 132, 199)

    p_b6 = doc.add_paragraph()
    p_b6.add_run('• Mục tiêu chứng minh: ').bold = True
    p_b6.add_run('Tính nguyên tử (Atomicity) theo chuẩn ACID - Nếu phát sinh lỗi trong quá trình tính điểm hoặc nộp bài, toàn bộ giao dịch được hoàn tác về trạng thái ban đầu, không lưu dữ liệu dở dang.\n')
    p_b6.add_run('• Thao tác trên pgAdmin: ').bold = True
    p_b6.add_run('Tại Tab 1 (06_demo.sql), bôi đen đoạn Mục 6.2 & 6.3 > Nhấn F5.\n')
    p_b6.add_run('• Lời thoại thuyết trình trước Thầy:\n').bold = True
    
    r_say6 = p_b6.add_run(
        '\"Cuối cùng là kiểm chứng Tính nguyên tử ACID bằng cơ chế ROLLBACK.\n\n'
        'Trong giao dịch nộp bài, nếu xảy ra sự cố đột ngột ở bước tính điểm: '
        'Em vừa thực hiện một giao dịch có lỗi cố ý và kích hoạt lệnh ROLLBACK. '
        'Kết quả kiểm tra ở bảng cau_tra_loi cho thấy thuộc tính lan_cap_nhat của câu trả lời số 20 vẫn giữ nguyên giá trị là 2, hoàn toàn không bị cập nhật dở dang hay sinh dữ liệu rác.\n\n'
        'Phần trình bày chuyên sâu Chương 6 của nhóm em đến đây là kết thúc, em xin cảm ơn thầy cô đã lắng nghe ạ!\"\n'
    )
    r_say6.font.color.rgb = RGBColor(15, 23, 42)
    r_say6.italic = True

    add_placeholder(doc, 'Kiểm chứng hoàn tác giao dịch bằng ROLLBACK (Khớp Hình 7.6 Báo cáo)', 'Ảnh chụp màn hình lan_cap_nhat vẫn bằng 2 sau khi thực thi lệnh ROLLBACK')

    # --- PHẦN 4 ---
    h4 = doc.add_heading('PHẦN 4: HỎI ĐÁP PHÒNG THỦ KHI GIẢNG VIÊN VẤN ĐÁP THÊM', level=1)
    h4.style.font.color.rgb = RGBColor(30, 58, 138)

    qa_list = [
        ('Câu hỏi 1: Tại sao trong báo cáo viết ODL có từ khóa module, interface mà trong file Java lại viết class, extends?',
         'Trả lời: Dạ thưa thầy, theo chuẩn ODMG 3.0, ODL là ngôn ngữ đặc tả lược đồ (Schema Definition) độc lập công nghệ, nên bắt buộc dùng cú pháp module và interface. Còn file Java DemoOnlineExamOODB.java là bản hiện thực theo chuẩn ODMG Java Language Binding, trong đó module ánh xạ thành package/class bao ngoài, interface ánh xạ thành abstract class, và kiểu tập hợp set/list ánh xạ thành java.util.Set và java.util.List để có thể biên dịch và chạy thực nghiệm ạ.'),
        
        ('Câu hỏi 2: Cập nhật câu hỏi và đổi đáp án thì sao không coi là câu hỏi mới mà lại là phiên bản mới?',
         'Trả lời: Dạ thưa thầy, về mặt nghiệp vụ đo lường giáo dục, câu hỏi đó vẫn đo lường cùng một chuẩn đầu ra kiến thức và cùng chủ đề. Việc tạo phiên bản mới giúp lưu lại vết lịch sử (Audit Trail) để bộ môn theo dõi tiến hóa nội dung qua các năm và phân tích chất lượng câu hỏi (tỷ lệ đúng, độ phân biệt). Nếu tạo câu hỏi mới thì dữ liệu thống kê lịch sử sẽ bị đứt gãy hoàn toàn ạ.'),
        
        ('Câu hỏi 3: Phân hệ CSDL Hướng đối tượng có chạy demo được không?',
         'Trả lời: Dạ có ạ! Nhóm đã đóng gói toàn bộ mô hình đối tượng và thuật toán chấm điểm đa hình vào file DemoOnlineExamOODB.java. Chỉ cần gõ lệnh \"java DemoOnlineExamOODB.java\" trên máy là chương trình lập tức khởi tạo dữ liệu đối tượng mẫu và chạy mô phỏng chính xác thuật toán chấm điểm đa hình cũng như tái hiện đề lịch sử OQL 2 ạ.')
    ]

    for q, a in qa_list:
        p_qa = doc.add_paragraph()
        p_qa.add_run(f'{q}\n').bold = True
        p_qa.add_run(f'👉 {a}\n')

    add_placeholder(doc, 'Màn hình Console thực thi file DemoOnlineExamOODB.java', 'Ảnh chụp màn hình terminal khi chạy java DemoOnlineExamOODB.java hiển thị bảng chấm điểm đa hình và tái hiện đề OQL 2')

    out1 = r'D:\CSDLNC\Demo final\Huong_Dan_Demo_Chuong_6.docx'
    doc.save(out1)
    print('Generated successfully at:', out1)
    out2 = r'D:\CSDLNC\Huong_Dan_Demo_Chuong_6.docx'
    doc.save(out2)
    print('Generated copy at:', out2)

if __name__ == '__main__':
    create_document()
