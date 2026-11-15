-- =====================================================================
-- Đồ án 12: CSDL ngân hàng câu hỏi & thi trực tuyến có quản lý phiên bản
-- Học phần: Cơ sở dữ liệu nâng cao | DBMS: PostgreSQL 12+
-- File 01 (Bản tối ưu): Cài đặt bảng, khóa, ràng buộc toàn vẹn (Mục 5.2) & Chỉ mục (Mục 5.3)
-- Đồng bộ 100% với file Mo_Ta_Bang_Chuong_5_CSDLNC-v2.docx
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Xóa bảng cũ theo thứ tự ngược phụ thuộc (Đảm bảo NF08 - Khả năng tái lập)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS
    ket_qua,
    chi_tiet_cham,
    lua_chon_tra_loi,
    cau_tra_loi,
    luot_thi,
    cau_hoi_trong_de,
    phien_ban_de_thi,
    de_thi,
    phuong_an,
    phien_ban_cau_hoi,
    cau_hoi_tu_luan,
    cau_hoi_nhieu_dap_an,
    cau_hoi_mot_dap_an,
    cau_hoi,
    chu_de,
    mon_hoc,
    nguoi_dung
CASCADE;

-- =====================================================================
-- NHÓM 1 – QUẢN LÝ DANH MỤC VÀ NGÂN HÀNG CÂU HỎI
-- =====================================================================

-- 1. Bảng NGUOIDUNG
CREATE TABLE nguoi_dung (
    ma_nguoi_dung  INTEGER      GENERATED ALWAYS AS IDENTITY,
    ho_ten         VARCHAR(100) NOT NULL,
    email          VARCHAR(255) NOT NULL,
    mat_khau_hash  VARCHAR(255) NOT NULL,
    vai_tro        VARCHAR(20)  NOT NULL,
    trang_thai     VARCHAR(20)  NOT NULL DEFAULT 'HOAT_DONG',
    CONSTRAINT pk_nguoi_dung PRIMARY KEY (ma_nguoi_dung),
    CONSTRAINT ck_nguoi_dung_ho_ten CHECK (btrim(ho_ten) <> ''),
    CONSTRAINT ck_nguoi_dung_email CHECK (btrim(email) <> ''),
    CONSTRAINT ck_nguoi_dung_vai_tro
        CHECK (vai_tro IN ('QUAN_TRI', 'GIANG_VIEN', 'THI_SINH')),
    CONSTRAINT ck_nguoi_dung_trang_thai
        CHECK (trang_thai IN ('HOAT_DONG', 'BI_KHOA'))
);
-- Email duy nhất không phân biệt hoa/thường
CREATE UNIQUE INDEX uq_nguoi_dung_email ON nguoi_dung (lower(email));


-- 2. Bảng MONHOC
CREATE TABLE mon_hoc (
    ma_mon_hoc   INTEGER      GENERATED ALWAYS AS IDENTITY,
    ten_mon_hoc  VARCHAR(150) NOT NULL,
    mo_ta        TEXT,
    CONSTRAINT pk_mon_hoc PRIMARY KEY (ma_mon_hoc),
    CONSTRAINT uq_mon_hoc_ten UNIQUE (ten_mon_hoc),
    CONSTRAINT ck_mon_hoc_ten CHECK (btrim(ten_mon_hoc) <> '')
);


-- 3. Bảng CHUDE
CREATE TABLE chu_de (
    ma_chu_de      INTEGER      GENERATED ALWAYS AS IDENTITY,
    ma_mon_hoc     INTEGER      NOT NULL,
    ten_chu_de     VARCHAR(150) NOT NULL,
    mo_ta          TEXT,
    ma_chu_de_cha  INTEGER,
    CONSTRAINT pk_chu_de PRIMARY KEY (ma_chu_de),
    CONSTRAINT fk_chu_de_mon_hoc
        FOREIGN KEY (ma_mon_hoc) REFERENCES mon_hoc (ma_mon_hoc),
    -- Không trùng tên chủ đề trong cùng một môn học
    CONSTRAINT uq_chu_de_ten_trong_mon UNIQUE (ma_mon_hoc, ten_chu_de),
    -- Khóa phụ để FK ghép bên dưới kiểm soát chủ đề cha cùng môn học với chủ đề con
    CONSTRAINT uq_chu_de_mon_hoc UNIQUE (ma_chu_de, ma_mon_hoc),
    CONSTRAINT fk_chu_de_cha
        FOREIGN KEY (ma_chu_de_cha, ma_mon_hoc)
        REFERENCES chu_de (ma_chu_de, ma_mon_hoc),
    CONSTRAINT ck_chu_de_ten CHECK (btrim(ten_chu_de) <> ''),
    CONSTRAINT ck_chu_de_khong_tu_tham_chieu
        CHECK (ma_chu_de_cha IS NULL OR ma_chu_de_cha <> ma_chu_de)
);


-- 4. Bảng CAUHOI (Thực thể cha)
CREATE TABLE cau_hoi (
    ma_cau_hoi    INTEGER     GENERATED ALWAYS AS IDENTITY,
    ma_chu_de     INTEGER     NOT NULL,
    ma_nguoi_tao  INTEGER     NOT NULL,
    loai_cau_hoi  VARCHAR(20) NOT NULL,
    ngay_tao      TIMESTAMPTZ NOT NULL DEFAULT now(),
    trang_thai    VARCHAR(20) NOT NULL DEFAULT 'HOAT_DONG',
    CONSTRAINT pk_cau_hoi PRIMARY KEY (ma_cau_hoi),
    CONSTRAINT fk_cau_hoi_chu_de
        FOREIGN KEY (ma_chu_de) REFERENCES chu_de (ma_chu_de),
    CONSTRAINT fk_cau_hoi_nguoi_tao
        FOREIGN KEY (ma_nguoi_tao) REFERENCES nguoi_dung (ma_nguoi_dung),
    CONSTRAINT ck_cau_hoi_loai
        CHECK (loai_cau_hoi IN ('MOT_DAP_AN', 'NHIEU_DAP_AN', 'TU_LUAN')), -- BR01
    CONSTRAINT ck_cau_hoi_trang_thai
        CHECK (trang_thai IN ('HOAT_DONG', 'NGUNG_SU_DUNG'))
);

-- 5, 6, 7. Ba quan hệ con chuyên biệt hóa (Total & Disjoint - Mục 4.1.2)
CREATE TABLE cau_hoi_mot_dap_an (
    ma_cau_hoi INTEGER NOT NULL,
    CONSTRAINT pk_cau_hoi_mot_dap_an PRIMARY KEY (ma_cau_hoi),
    CONSTRAINT fk_cau_hoi_mot_dap_an_cha
        FOREIGN KEY (ma_cau_hoi) REFERENCES cau_hoi (ma_cau_hoi) ON DELETE CASCADE
);

CREATE TABLE cau_hoi_nhieu_dap_an (
    ma_cau_hoi INTEGER NOT NULL,
    CONSTRAINT pk_cau_hoi_nhieu_dap_an PRIMARY KEY (ma_cau_hoi),
    CONSTRAINT fk_cau_hoi_nhieu_dap_an_cha
        FOREIGN KEY (ma_cau_hoi) REFERENCES cau_hoi (ma_cau_hoi) ON DELETE CASCADE
);

CREATE TABLE cau_hoi_tu_luan (
    ma_cau_hoi INTEGER NOT NULL,
    CONSTRAINT pk_cau_hoi_tu_luan PRIMARY KEY (ma_cau_hoi),
    CONSTRAINT fk_cau_hoi_tu_luan_cha
        FOREIGN KEY (ma_cau_hoi) REFERENCES cau_hoi (ma_cau_hoi) ON DELETE CASCADE
);


-- 8. Bảng PHIENBANCAUHOI
CREATE TABLE phien_ban_cau_hoi (
    ma_phien_ban_ch      INTEGER     GENERATED ALWAYS AS IDENTITY,
    ma_cau_hoi           INTEGER     NOT NULL,
    so_phien_ban         INTEGER     NOT NULL,
    noi_dung             TEXT        NOT NULL,
    muc_do_kho           VARCHAR(15) NOT NULL,
    quy_tac_cham         VARCHAR(20) NOT NULL,
    huong_dan_cham       TEXT,
    ngay_tao             TIMESTAMPTZ NOT NULL DEFAULT now(),
    trang_thai_phien_ban VARCHAR(15) NOT NULL DEFAULT 'BAN_NHAP',
    CONSTRAINT pk_phien_ban_cau_hoi PRIMARY KEY (ma_phien_ban_ch),
    CONSTRAINT fk_pbch_cau_hoi
        FOREIGN KEY (ma_cau_hoi) REFERENCES cau_hoi (ma_cau_hoi),          -- BR02
    CONSTRAINT uq_pbch_cau_hoi_so_phien_ban UNIQUE (ma_cau_hoi, so_phien_ban), -- BR03
    CONSTRAINT ck_pbch_so_phien_ban CHECK (so_phien_ban > 0),
    CONSTRAINT ck_pbch_noi_dung CHECK (btrim(noi_dung) <> ''),
    CONSTRAINT ck_pbch_muc_do_kho
        CHECK (muc_do_kho IN ('DE', 'TRUNG_BINH', 'KHO')),
    CONSTRAINT ck_pbch_quy_tac_cham
        CHECK (quy_tac_cham IN ('TOAN_PHAN', 'THU_CONG')),
    -- BR07: Nếu quy tắc chấm là THU_CONG (câu tự luận) thì cần có hướng dẫn chấm
    CONSTRAINT ck_pbch_huong_dan_tu_luan
        CHECK (quy_tac_cham <> 'THU_CONG' OR (huong_dan_cham IS NOT NULL AND btrim(huong_dan_cham) <> '')),
    CONSTRAINT ck_pbch_trang_thai
        CHECK (trang_thai_phien_ban IN ('BAN_NHAP', 'DA_CONG_BO'))
);


-- 9. Bảng PHUONGAN
CREATE TABLE phuong_an (
    ma_phuong_an       INTEGER GENERATED ALWAYS AS IDENTITY,
    ma_phien_ban_ch    INTEGER NOT NULL,
    noi_dung_phuong_an TEXT    NOT NULL,
    thu_tu             INTEGER NOT NULL,
    la_dap_an_dung     BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_phuong_an PRIMARY KEY (ma_phuong_an),
    -- ON DELETE CASCADE cho phép xóa phiên bản câu hỏi khi còn ở trạng thái BAN_NHAP
    CONSTRAINT fk_phuong_an_pbch
        FOREIGN KEY (ma_phien_ban_ch) REFERENCES phien_ban_cau_hoi (ma_phien_ban_ch) ON DELETE CASCADE,
    CONSTRAINT uq_phuong_an_thu_tu UNIQUE (ma_phien_ban_ch, thu_tu),
    CONSTRAINT ck_phuong_an_noi_dung CHECK (btrim(noi_dung_phuong_an) <> ''),
    CONSTRAINT ck_phuong_an_thu_tu CHECK (thu_tu > 0)
);

-- =====================================================================
-- NHÓM 2 – QUẢN LÝ ĐỀ THI
-- =====================================================================

-- 10. Bảng DETHI
CREATE TABLE de_thi (
    ma_de_thi     INTEGER      GENERATED ALWAYS AS IDENTITY,
    ma_mon_hoc    INTEGER      NOT NULL,
    ma_nguoi_tao  INTEGER      NOT NULL,
    ten_de_thi    VARCHAR(200) NOT NULL,
    ngay_tao      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_de_thi PRIMARY KEY (ma_de_thi),
    CONSTRAINT fk_de_thi_mon_hoc
        FOREIGN KEY (ma_mon_hoc) REFERENCES mon_hoc (ma_mon_hoc),          -- BR08
    CONSTRAINT fk_de_thi_nguoi_tao
        FOREIGN KEY (ma_nguoi_tao) REFERENCES nguoi_dung (ma_nguoi_dung),
    CONSTRAINT ck_de_thi_ten CHECK (btrim(ten_de_thi) <> '')
);


-- 11. Bảng PHIENBANDETHI
CREATE TABLE phien_ban_de_thi (
    ma_phien_ban_de   INTEGER     GENERATED ALWAYS AS IDENTITY,
    ma_de_thi         INTEGER     NOT NULL,
    so_phien_ban      INTEGER     NOT NULL,
    thoi_luong        INTEGER     NOT NULL,                                -- tính bằng phút
    so_lan_thi_toi_da INTEGER     NOT NULL DEFAULT 1,
    thoi_gian_mo      TIMESTAMPTZ NOT NULL,
    thoi_gian_dong    TIMESTAMPTZ NOT NULL,
    ngay_tao          TIMESTAMPTZ NOT NULL DEFAULT now(),
    trang_thai        VARCHAR(15) NOT NULL DEFAULT 'BAN_NHAP',
    CONSTRAINT pk_phien_ban_de_thi PRIMARY KEY (ma_phien_ban_de),
    CONSTRAINT fk_pbdt_de_thi
        FOREIGN KEY (ma_de_thi) REFERENCES de_thi (ma_de_thi),
    CONSTRAINT uq_pbdt_de_thi_so_phien_ban UNIQUE (ma_de_thi, so_phien_ban),
    CONSTRAINT ck_pbdt_so_phien_ban CHECK (so_phien_ban > 0),
    CONSTRAINT ck_pbdt_thoi_luong CHECK (thoi_luong > 0),                  -- BR11
    CONSTRAINT ck_pbdt_so_lan_thi CHECK (so_lan_thi_toi_da > 0),           -- BR11
    CONSTRAINT ck_pbdt_thoi_gian CHECK (thoi_gian_dong > thoi_gian_mo),
    CONSTRAINT ck_pbdt_trang_thai
        CHECK (trang_thai IN ('BAN_NHAP', 'DA_CONG_BO'))
);


-- 12. Bảng CAUHOITRONGDE
CREATE TABLE cau_hoi_trong_de (
    ma_chi_tiet_de   INTEGER      GENERATED ALWAYS AS IDENTITY,
    ma_phien_ban_de  INTEGER      NOT NULL,
    ma_phien_ban_ch  INTEGER      NOT NULL,
    thu_tu_cau_hoi   INTEGER      NOT NULL,
    diem_toi_da      NUMERIC(5,2) NOT NULL,
    CONSTRAINT pk_cau_hoi_trong_de PRIMARY KEY (ma_chi_tiet_de),
    CONSTRAINT fk_chtd_phien_ban_de
        FOREIGN KEY (ma_phien_ban_de) REFERENCES phien_ban_de_thi (ma_phien_ban_de) ON DELETE CASCADE,
    CONSTRAINT fk_chtd_phien_ban_ch
        FOREIGN KEY (ma_phien_ban_ch) REFERENCES phien_ban_cau_hoi (ma_phien_ban_ch), -- BR09
    CONSTRAINT uq_chtd_thu_tu UNIQUE (ma_phien_ban_de, thu_tu_cau_hoi),
    -- Chặn đưa trùng 1 phiên bản câu hỏi nhiều lần vào cùng 1 phiên bản đề thi
    CONSTRAINT uq_chtd_de_cau_hoi UNIQUE (ma_phien_ban_de, ma_phien_ban_ch),
    CONSTRAINT ck_chtd_thu_tu CHECK (thu_tu_cau_hoi > 0),
    CONSTRAINT ck_chtd_diem_toi_da CHECK (diem_toi_da > 0)                 -- BR10
);

-- =====================================================================
-- NHÓM 3 – QUẢN LÝ LƯỢT THI VÀ BÀI LÀM
-- =====================================================================

-- 13. Bảng LUOTTHI
CREATE TABLE luot_thi (
    ma_luot_thi       BIGINT      GENERATED ALWAYS AS IDENTITY,
    ma_nguoi_dung     INTEGER     NOT NULL,
    ma_phien_ban_de   INTEGER     NOT NULL,
    lan_thi           INTEGER     NOT NULL,
    thoi_gian_bat_dau TIMESTAMPTZ NOT NULL DEFAULT now(),
    han_nop_bai       TIMESTAMPTZ NOT NULL,
    thoi_gian_nop     TIMESTAMPTZ,
    trang_thai        VARCHAR(15) NOT NULL DEFAULT 'DANG_LAM',
    CONSTRAINT pk_luot_thi PRIMARY KEY (ma_luot_thi),
    CONSTRAINT fk_luot_thi_nguoi_dung
        FOREIGN KEY (ma_nguoi_dung) REFERENCES nguoi_dung (ma_nguoi_dung), -- BR13
    CONSTRAINT fk_luot_thi_phien_ban_de
        FOREIGN KEY (ma_phien_ban_de) REFERENCES phien_ban_de_thi (ma_phien_ban_de), -- BR13
    CONSTRAINT uq_luot_thi_lan_thi UNIQUE (ma_nguoi_dung, ma_phien_ban_de, lan_thi),
    CONSTRAINT ck_luot_thi_lan_thi CHECK (lan_thi > 0),
    CONSTRAINT ck_luot_thi_trang_thai
        CHECK (trang_thai IN ('DANG_LAM', 'DA_NOP', 'CHO_CHAM', 'HOAN_TAT')),
    CONSTRAINT ck_luot_thi_han_nop CHECK (han_nop_bai > thoi_gian_bat_dau),
    CONSTRAINT ck_luot_thi_thoi_gian_nop
        CHECK (thoi_gian_nop IS NULL OR thoi_gian_nop >= thoi_gian_bat_dau),
    -- Ràng buộc nhất quán trạng thái nộp bài (Nền tảng cho BR17, BR18)
    CONSTRAINT ck_luot_thi_nop_nhat_quan
        CHECK ((trang_thai = 'DANG_LAM') = (thoi_gian_nop IS NULL))
);


-- 14. Bảng CAUTRALOI
CREATE TABLE cau_tra_loi (
    ma_cau_tra_loi     BIGINT      GENERATED ALWAYS AS IDENTITY,
    ma_luot_thi        BIGINT      NOT NULL,
    ma_chi_tiet_de     INTEGER     NOT NULL,
    noi_dung_tu_luan   TEXT,
    lan_cap_nhat       INTEGER     NOT NULL DEFAULT 0,
    thoi_gian_cap_nhat TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT pk_cau_tra_loi PRIMARY KEY (ma_cau_tra_loi),
    CONSTRAINT fk_ctl_luot_thi
        FOREIGN KEY (ma_luot_thi) REFERENCES luot_thi (ma_luot_thi),       -- BR15
    CONSTRAINT fk_ctl_chi_tiet_de
        FOREIGN KEY (ma_chi_tiet_de) REFERENCES cau_hoi_trong_de (ma_chi_tiet_de), -- BR15
    CONSTRAINT uq_ctl_luot_thi_cau_hoi UNIQUE (ma_luot_thi, ma_chi_tiet_de),       -- BR16
    CONSTRAINT ck_ctl_lan_cap_nhat CHECK (lan_cap_nhat >= 0)
);


-- 15. Bảng LUACHONTRALOI
CREATE TABLE lua_chon_tra_loi (
    ma_cau_tra_loi BIGINT  NOT NULL,
    ma_phuong_an   INTEGER NOT NULL,
    CONSTRAINT pk_lua_chon_tra_loi PRIMARY KEY (ma_cau_tra_loi, ma_phuong_an),
    CONSTRAINT fk_lctl_cau_tra_loi
        FOREIGN KEY (ma_cau_tra_loi) REFERENCES cau_tra_loi (ma_cau_tra_loi) ON DELETE CASCADE,
    CONSTRAINT fk_lctl_phuong_an
        FOREIGN KEY (ma_phuong_an) REFERENCES phuong_an (ma_phuong_an)
);

-- =====================================================================
-- NHÓM 4 – QUẢN LÝ CHẤM ĐIỂM VÀ KẾT QUẢ
-- =====================================================================

-- 16. Bảng CHITIETCHAM
CREATE TABLE chi_tiet_cham (
    ma_chi_tiet_cham BIGINT       GENERATED ALWAYS AS IDENTITY,
    ma_cau_tra_loi   BIGINT       NOT NULL,
    diem_dat_duoc    NUMERIC(5,2),
    trang_thai_cham  VARCHAR(15)  NOT NULL DEFAULT 'CHO_CHAM',
    ma_nguoi_cham    INTEGER,                                              -- NULL = chấm tự động
    thoi_gian_cham   TIMESTAMPTZ,
    nhan_xet         TEXT,
    CONSTRAINT pk_chi_tiet_cham PRIMARY KEY (ma_chi_tiet_cham),
    CONSTRAINT fk_ctc_cau_tra_loi
        FOREIGN KEY (ma_cau_tra_loi) REFERENCES cau_tra_loi (ma_cau_tra_loi) ON DELETE CASCADE,
    CONSTRAINT fk_ctc_nguoi_cham
        FOREIGN KEY (ma_nguoi_cham) REFERENCES nguoi_dung (ma_nguoi_dung),
    CONSTRAINT uq_ctc_cau_tra_loi UNIQUE (ma_cau_tra_loi),                 -- Quan hệ 1 : 0..1
    CONSTRAINT ck_ctc_trang_thai
        CHECK (trang_thai_cham IN ('CHO_CHAM', 'DA_CHAM')),
    CONSTRAINT ck_ctc_diem CHECK (diem_dat_duoc IS NULL OR diem_dat_duoc >= 0),
    -- Nhất quán: Đã chấm <=> Có điểm số & Có thời điểm chấm; Chờ chấm <=> Chưa có điểm, thời gian & người chấm
    CONSTRAINT ck_ctc_cham_nhat_quan
        CHECK (
            (trang_thai_cham = 'DA_CHAM' AND diem_dat_duoc IS NOT NULL AND thoi_gian_cham IS NOT NULL)
            OR
            (trang_thai_cham = 'CHO_CHAM' AND diem_dat_duoc IS NULL AND thoi_gian_cham IS NULL AND ma_nguoi_cham IS NULL)
        )
);


-- 17. Bảng KETQUA
CREATE TABLE ket_qua (
    ma_ket_qua         BIGINT       GENERATED ALWAYS AS IDENTITY,
    ma_luot_thi        BIGINT       NOT NULL,
    tong_diem          NUMERIC(7,2) NOT NULL,
    thoi_gian_hoan_tat TIMESTAMPTZ  NOT NULL DEFAULT now(),
    trang_thai_ket_qua VARCHAR(15)  NOT NULL DEFAULT 'CHINH_THUC',
    CONSTRAINT pk_ket_qua PRIMARY KEY (ma_ket_qua),
    CONSTRAINT fk_ket_qua_luot_thi
        FOREIGN KEY (ma_luot_thi) REFERENCES luot_thi (ma_luot_thi),
    CONSTRAINT uq_ket_qua_luot_thi UNIQUE (ma_luot_thi),                   -- BR22: Tối đa 1 kết quả/lượt thi
    CONSTRAINT ck_ket_qua_tong_diem CHECK (tong_diem >= 0),
    CONSTRAINT ck_ket_qua_trang_thai
        CHECK (trang_thai_ket_qua IN ('CHINH_THUC', 'DA_HUY'))
);

-- =====================================================================
-- THIẾT KẾ CHỈ MỤC (INDEX) TỐI ƯU TRUY VẤN (Phục vụ Mục 5.3 Báo cáo)
-- =====================================================================

-- 1. Chỉ mục hỗ trợ truy vấn đệ quy cây chủ đề theo môn học
CREATE INDEX idx_chu_de_mon_cha ON chu_de (ma_mon_hoc, ma_chu_de_cha);

-- 2. Chỉ mục lọc câu hỏi đang hoạt động theo chủ đề và loại câu hỏi
CREATE INDEX idx_cau_hoi_chu_de_loai ON cau_hoi (ma_chu_de, loai_cau_hoi)
    WHERE trang_thai = 'HOAT_DONG';

-- 3. Chỉ mục tìm kiếm phiên bản câu hỏi đã công bố theo mức độ khó (Phục vụ rút câu hỏi tạo đề)
CREATE INDEX idx_pbch_cong_bo_do_kho ON phien_ban_cau_hoi (ma_cau_hoi, muc_do_kho)
    WHERE trang_thai_phien_ban = 'DA_CONG_BO';

-- 4. Chỉ mục tra cứu nhanh các phương án đúng của một phiên bản câu hỏi khi chấm tự động
CREATE INDEX idx_phuong_an_dap_an_dung ON phuong_an (ma_phien_ban_ch, ma_phuong_an)
    WHERE la_dap_an_dung = TRUE;

-- 5. Chỉ mục Partial Unique: Chặn 1 thí sinh mở đồng thời 2 lượt thi DANG_LAM trên cùng 1 phiên bản đề
CREATE UNIQUE INDEX uq_luot_thi_dang_lam_duy_nhat
    ON luot_thi (ma_nguoi_dung, ma_phien_ban_de)
    WHERE trang_thai = 'DANG_LAM';

-- 6. Chỉ mục trên các khóa ngoại tần suất JOIN cao (Lượt thi, Câu trả lời, Chấm điểm)
CREATE INDEX idx_luot_thi_de_trang_thai ON luot_thi (ma_phien_ban_de, trang_thai);
CREATE INDEX idx_cau_tra_loi_chi_tiet_de ON cau_tra_loi (ma_chi_tiet_de);
CREATE INDEX idx_lua_chon_phuong_an ON lua_chon_tra_loi (ma_phuong_an);
CREATE INDEX idx_chi_tiet_cham_cho_cham ON chi_tiet_cham (trang_thai_cham)
    WHERE trang_thai_cham = 'CHO_CHAM';

-- =====================================================================
-- Đồ án 12: CSDL ngân hàng câu hỏi & thi trực tuyến có quản lý phiên bản
-- File 02: Dữ liệu mẫu kiểm thử (Sample Data) cho 17 bảng
-- Lưu ý: Có thể chạy lại nhiều lần nhờ lệnh TRUNCATE ... RESTART IDENTITY
-- =====================================================================

BEGIN;

-- Xóa dữ liệu cũ và đưa bộ đếm IDENTITY về 1
TRUNCATE TABLE
    ket_qua,
    chi_tiet_cham,
    lua_chon_tra_loi,
    cau_tra_loi,
    luot_thi,
    cau_hoi_trong_de,
    phien_ban_de_thi,
    de_thi,
    phuong_an,
    phien_ban_cau_hoi,
    cau_hoi_tu_luan,
    cau_hoi_nhieu_dap_an,
    cau_hoi_mot_dap_an,
    cau_hoi,
    chu_de,
    mon_hoc,
    nguoi_dung
RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------------
-- 1. Bảng NGUOIDUNG (1 Quản trị, 2 Giảng viên, 4 Thí sinh)
-- ---------------------------------------------------------------------
INSERT INTO nguoi_dung (ma_nguoi_dung, ho_ten, email, mat_khau_hash, vai_tro, trang_thai)
OVERRIDING SYSTEM VALUE VALUES
    (1, 'Quản Trị Hệ Thống',   'admin@sgu.edu.vn',     '$2b$12$hash_admin', 'QUAN_TRI',   'HOAT_DONG'),
    (2, 'Huỳnh Minh Trí',      'hmtri@sgu.edu.vn',     '$2b$12$hash_gv01',  'GIANG_VIEN', 'HOAT_DONG'),
    (3, 'Nguyễn Thanh Sang',   'ntsang@sgu.edu.vn',    '$2b$12$hash_gv02',  'GIANG_VIEN', 'HOAT_DONG'),
    (4, 'Khưu Minh Đức',       'kmduc@sv.sgu.edu.vn',  '$2b$12$hash_sv01',  'THI_SINH',   'HOAT_DONG'),
    (5, 'Nguyễn Mạnh Dũng',    'nmdung@sv.sgu.edu.vn', '$2b$12$hash_sv02',  'THI_SINH',   'HOAT_DONG'),
    (6, 'Trần Thị Ngọc Ánh',   'ttnanh@sv.sgu.edu.vn', '$2b$12$hash_sv03',  'THI_SINH',   'HOAT_DONG'),
    (7, 'Lê Hoàng Nam',        'lhnam@sv.sgu.edu.vn',  '$2b$12$hash_sv04',  'THI_SINH',   'HOAT_DONG');

-- ---------------------------------------------------------------------
-- 2. Bảng MONHOC
-- ---------------------------------------------------------------------
INSERT INTO mon_hoc (ma_mon_hoc, ten_mon_hoc, mo_ta)
OVERRIDING SYSTEM VALUE VALUES
    (1, 'Cơ sở dữ liệu nâng cao',     'Học phần chuyên sâu về EER, chuẩn hóa, OODB, quản lý phiên bản và giao dịch đồng thời.'),
    (2, 'Hệ quản trị cơ sở dữ liệu', 'Học phần về kiến trúc lưu trữ, chỉ mục, tối ưu hóa truy vấn và bảo mật CSDL.');

-- ---------------------------------------------------------------------
-- 3. Bảng CHUDE (Có phân cấp cha - con trong cùng môn học)
-- ---------------------------------------------------------------------
INSERT INTO chu_de (ma_chu_de, ma_mon_hoc, ten_chu_de, mo_ta, ma_chu_de_cha)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'Thiết kế và Chuẩn hóa CSDL',             'Chủ đề gốc về thiết kế mức quan niệm và mức logic', NULL),
    (2, 1, 'Mô hình EER và Chuyên biệt hóa',          'Kế thừa lớp cha - lớp con, ràng buộc Total/Disjoint', 1),
    (3, 1, 'Phụ thuộc hàm và Dạng chuẩn BCNF/4NF',    'Bao đóng, phủ tối tiểu, chuẩn hóa 3NF, BCNF, 4NF', 1),
    (4, 1, 'Quản lý Giao dịch và Đồng thời',          'Chủ đề gốc về Transaction ACID và Concurrency', NULL),
    (5, 1, 'Khóa dữ liệu (Locking) và Mức cô lập',    'Xử lý cạnh tranh lưu bài tự động và nộp bài đồng thời', 4),
    (6, 2, 'Tối ưu hóa Chỉ mục và Truy vấn',          'Cấu trúc B-Tree, Partial Index và EXPLAIN ANALYZE', NULL);

-- ---------------------------------------------------------------------
-- 4. Bảng CAUHOI (6 câu hỏi gốc thuộc 3 loại)
-- ---------------------------------------------------------------------
INSERT INTO cau_hoi (ma_cau_hoi, ma_chu_de, ma_nguoi_tao, loai_cau_hoi, ngay_tao, trang_thai)
OVERRIDING SYSTEM VALUE VALUES
    (1, 2, 2, 'MOT_DAP_AN',   '2026-09-01 08:00:00+07', 'HOAT_DONG'),
    (2, 3, 2, 'MOT_DAP_AN',   '2026-09-02 08:30:00+07', 'HOAT_DONG'),
    (3, 3, 2, 'NHIEU_DAP_AN', '2026-09-03 09:00:00+07', 'HOAT_DONG'),
    (4, 5, 2, 'NHIEU_DAP_AN', '2026-09-04 10:00:00+07', 'HOAT_DONG'),
    (5, 5, 2, 'TU_LUAN',      '2026-09-05 14:00:00+07', 'HOAT_DONG'),
    (6, 2, 3, 'MOT_DAP_AN',   '2026-09-06 15:00:00+07', 'HOAT_DONG');

-- ---------------------------------------------------------------------
-- 5, 6, 7. Ba bảng con chuyên biệt hóa (Total & Disjoint)
-- ---------------------------------------------------------------------
INSERT INTO cau_hoi_mot_dap_an (ma_cau_hoi) VALUES (1), (2), (6);
INSERT INTO cau_hoi_nhieu_dap_an (ma_cau_hoi) VALUES (3), (4);
INSERT INTO cau_hoi_tu_luan (ma_cau_hoi) VALUES (5);

-- ---------------------------------------------------------------------
-- 8. Bảng PHIENBANCAUHOI
-- Lưu ý: Câu hỏi 1 có 2 phiên bản (v1 và v2) để kiểm thử quản lý phiên bản!
-- ---------------------------------------------------------------------
INSERT INTO phien_ban_cau_hoi (
    ma_phien_ban_ch, ma_cau_hoi, so_phien_ban, noi_dung,
    muc_do_kho, quy_tac_cham, huong_dan_cham, ngay_tao, trang_thai_phien_ban
)
OVERRIDING SYSTEM VALUE VALUES
    -- Câu 1 - Phiên bản 1 (Dùng trong Đề giữa kỳ v1)
    (1, 1, 1, 'Trong sơ đồ EER, ký hiệu chữ "d" nằm trong vòng tròn chuyên biệt hóa biểu diễn tính chất nào?',
     'DE', 'TOAN_PHAN', NULL, '2026-09-01 08:10:00+07', 'DA_CONG_BO'),

    -- Câu 1 - Phiên bản 2 (Chỉnh sửa nội dung, nâng độ khó và đổi vị trí đáp án đúng sau kỳ thi 1)
    (2, 1, 2, 'Trong mô hình EER mở rộng, ràng buộc chuyên biệt hóa loại trừ (Disjoint) kết hợp toàn phần (Total) mang ý nghĩa nào sau đây?',
     'TRUNG_BINH', 'TOAN_PHAN', NULL, '2026-10-01 09:00:00+07', 'DA_CONG_BO'),

    -- Câu 2 - Phiên bản 1 (1 đáp án)
    (3, 2, 1, 'Một lược đồ quan hệ R đạt dạng chuẩn BCNF khi và chỉ khi mọi phụ thuộc hàm không tầm thường X -> A trong R đều thỏa mãn điều kiện nào?',
     'TRUNG_BINH', 'TOAN_PHAN', NULL, '2026-09-02 08:40:00+07', 'DA_CONG_BO'),

    -- Câu 3 - Phiên bản 1 (Nhiều đáp án)
    (4, 3, 1, 'Cho lược đồ R(C, D, P, S, N, M, Q) với tập phụ thuộc hàm F = {C -> D; P -> C, S, N, M, Q; CS -> P}. Những tập thuộc tính nào sau đây là khóa ứng viên của R? (Chọn tất cả đáp án đúng)',
     'KHO', 'TOAN_PHAN', NULL, '2026-09-03 09:15:00+07', 'DA_CONG_BO'),

    -- Câu 4 - Phiên bản 1 (Nhiều đáp án)
    (5, 4, 1, 'Để ngăn chặn tình trạng lưu bài tự động (autosave) ghi đè lên bài thi đã nộp khi xảy ra cạnh tranh đồng thời, cần kết hợp những kỹ thuật nào trong PostgreSQL? (Chọn tất cả đáp án đúng)',
     'KHO', 'TOAN_PHAN', NULL, '2026-09-04 10:20:00+07', 'DA_CONG_BO'),

    -- Câu 5 - Phiên bản 1 (Tự luận chấm thủ công)
    (6, 5, 1, 'Hãy phân tích kịch bản hai phiên giao dịch cùng gửi yêu cầu nộp bài đồng thời cho một lượt thi và trình bày giải pháp khóa bản ghi để đảm bảo chỉ tạo duy nhất một kết quả chính thức.',
     'KHO', 'THU_CONG',
     'Thí sinh cần nêu đủ 3 ý: (1) Sử dụng SELECT ... FOR UPDATE trên bảng luot_thi để khóa dòng; (2) Kiểm tra trang_thai = DANG_LAM trước khi chốt; (3) Ràng buộc UNIQUE(ma_luot_thi) trên bảng ket_qua.',
     '2026-09-05 14:30:00+07', 'DA_CONG_BO'),

    -- Câu 6 - Phiên bản 1 (1 đáp án - Câu hỏi dự trữ trong ngân hàng)
    (7, 6, 1, 'Khi chuyển đổi cấu trúc chuyên biệt hóa toàn phần và loại trừ từ EER sang lược đồ quan hệ theo phương án tạo bảng cho thực thể cha và các thực thể con, khóa của các bảng con được thiết kế như thế nào?',
     'DE', 'TOAN_PHAN', NULL, '2026-09-06 15:10:00+07', 'DA_CONG_BO');

-- ---------------------------------------------------------------------
-- 9. Bảng PHUONGAN (Dành cho các phiên bản câu hỏi trắc nghiệm)
-- ---------------------------------------------------------------------
INSERT INTO phuong_an (ma_phuong_an, ma_phien_ban_ch, noi_dung_phuong_an, thu_tu, la_dap_an_dung)
OVERRIDING SYSTEM VALUE VALUES
    -- Phương án của PB 1 (Câu 1 v1 - Đáp án đúng ở thứ tự 1)
    (1,  1, 'Tính loại trừ (Disjoint): một thực thể cha chỉ thuộc tối đa một thực thể con.', 1, TRUE),
    (2,  1, 'Tính chồng lấp (Overlapping): một thực thể cha có thể thuộc nhiều thực thể con.', 2, FALSE),
    (3,  1, 'Tính phụ thuộc tồn tại của thực thể yếu.', 3, FALSE),
    (4,  1, 'Tính đa trị của thuộc tính khóa.', 4, FALSE),

    -- Phương án của PB 2 (Câu 1 v2 - Đổi đáp án đúng sang thứ tự 2)
    (5,  2, 'Mỗi câu hỏi có thể thuộc nhiều loại câu hỏi cùng lúc.', 1, FALSE),
    (6,  2, 'Mỗi câu hỏi bắt buộc phải thuộc đúng một và chỉ một trong ba thực thể con.', 2, TRUE),
    (7,  2, 'Một câu hỏi có thể không thuộc thực thể con nào.', 3, FALSE),
    (8,  2, 'Các thực thể con không kế thừa định danh của thực thể cha.', 4, FALSE),

    -- Phương án của PB 3 (Câu 2 v1 - Đáp án đúng ở thứ tự 2)
    (9,  3, 'A là thuộc tính nguyên tố thuộc một khóa ứng viên.', 1, FALSE),
    (10, 3, 'X phải là một siêu khóa (Superkey) của quan hệ R.', 2, TRUE),
    (11, 3, 'X không chứa bất kỳ thuộc tính khóa nào.', 3, FALSE),
    (12, 3, 'R không có các thuộc tính đa trị.', 4, FALSE),

    -- Phương án của PB 4 (Câu 3 v1 - Nhiều đáp án: Đúng cả 1 và 2)
    (13, 4, 'Tập thuộc tính {P} (Mã phiên bản câu hỏi)', 1, TRUE),
    (14, 4, 'Tập thuộc tính {C, S} (Cặp Mã câu hỏi và Số phiên bản)', 2, TRUE),
    (15, 4, 'Tập thuộc tính {C, D} (Mã câu hỏi và Mã chủ đề)', 3, FALSE),
    (16, 4, 'Tập thuộc tính {S, M} (Số phiên bản và Mức độ khó)', 4, FALSE),

    -- Phương án của PB 5 (Câu 4 v1 - Nhiều đáp án: Đúng cả 1 và 3)
    (17, 5, 'Khóa bản ghi lượt thi bằng câu lệnh SELECT ... FOR UPDATE trong giao dịch.', 1, TRUE),
    (18, 5, 'Cho phép cập nhật tự do bảng cau_tra_loi không cần kiểm tra trạng thái lượt thi.', 2, FALSE),
    (19, 5, 'Kiểm tra điều kiện trang_thai = ''DANG_LAM'' trước khi ghi nhận cập nhật hoặc chốt nộp bài.', 3, TRUE),
    (20, 5, 'Xóa toàn bộ lịch sử lượt thi sau khi chấm điểm.', 4, FALSE),

    -- Phương án của PB 7 (Câu 6 v1 - Đáp án đúng ở thứ tự 1)
    (21, 7, 'Khóa chính của bảng con đồng thời là khóa ngoại tham chiếu trực tiếp đến khóa chính bảng cha.', 1, TRUE),
    (22, 7, 'Mỗi bảng con tự sinh một khóa chính độc lập không liên kết với bảng cha.', 2, FALSE),
    (23, 7, 'Gộp toàn bộ thuộc tính vào bảng phương án.', 3, FALSE),
    (24, 7, 'Không cần sử dụng khóa chính cho các bảng con.', 4, FALSE);

-- ---------------------------------------------------------------------
-- 10. Bảng DETHI
-- ---------------------------------------------------------------------
INSERT INTO de_thi (ma_de_thi, ma_mon_hoc, ma_nguoi_tao, ten_de_thi, ngay_tao)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 2, 'Đề kiểm tra giữa kỳ - Cơ sở dữ liệu nâng cao', '2026-09-10 08:00:00+07'),
    (2, 1, 2, 'Đề thi kết thúc học phần - Cơ sở dữ liệu nâng cao', '2026-10-05 08:00:00+07');

-- ---------------------------------------------------------------------
-- 11. Bảng PHIENBANDETHI
-- ---------------------------------------------------------------------
INSERT INTO phien_ban_de_thi (
    ma_phien_ban_de, ma_de_thi, so_phien_ban, thoi_luong,
    so_lan_thi_toi_da, thoi_gian_mo, thoi_gian_dong, ngay_tao, trang_thai
)
OVERRIDING SYSTEM VALUE VALUES
    -- Phiên bản đề 1: Đề giữa kỳ đợt 1 (Sử dụng Câu 1 phiên bản 1 cũ)
    (1, 1, 1, 45, 2, '2026-09-15 07:00:00+07', '2026-09-15 23:00:00+07', '2026-09-10 09:00:00+07', 'DA_CONG_BO'),
    -- Phiên bản đề 2: Đề giữa kỳ đợt 2 (Cập nhật sang Câu 1 phiên bản 2 mới)
    (2, 1, 2, 45, 2, '2026-10-10 07:00:00+07', '2026-12-30 23:00:00+07', '2026-10-02 09:00:00+07', 'DA_CONG_BO'),
    -- Phiên bản đề 3: Đề cuối kỳ (Kết hợp trắc nghiệm + câu hỏi tự luận PB 6)
    (3, 2, 1, 60, 1, '2026-10-20 07:00:00+07', '2026-12-30 23:00:00+07', '2026-10-05 09:00:00+07', 'DA_CONG_BO');

-- ---------------------------------------------------------------------
-- 12. Bảng CAUHOITRONGDE
-- ---------------------------------------------------------------------
INSERT INTO cau_hoi_trong_de (ma_chi_tiet_de, ma_phien_ban_de, ma_phien_ban_ch, thu_tu_cau_hoi, diem_toi_da)
OVERRIDING SYSTEM VALUE VALUES
    -- Đề giữa kỳ v1 (ma_phien_ban_de = 1): Dùng PB 1 (v1 của câu 1), PB 3, PB 4, PB 5
    (1,  1, 1, 1, 2.50),
    (2,  1, 3, 2, 2.50),
    (3,  1, 4, 3, 2.50),
    (4,  1, 5, 4, 2.50),

    -- Đề giữa kỳ v2 (ma_phien_ban_de = 2): Dùng PB 2 (v2 của câu 1), PB 3, PB 4, PB 5
    (5,  2, 2, 1, 2.50),
    (6,  2, 3, 2, 2.50),
    (7,  2, 4, 3, 2.50),
    (8,  2, 5, 4, 2.50),

    -- Đề cuối kỳ v1 (ma_phien_ban_de = 3): Dùng PB 2, PB 4 và PB 6 (Tự luận 4.0 điểm)
    (9,  3, 2, 1, 3.00),
    (10, 3, 4, 2, 3.00),
    (11, 3, 6, 3, 4.00);

-- ---------------------------------------------------------------------
-- 13. Bảng LUOTTHI
-- ---------------------------------------------------------------------
INSERT INTO luot_thi (
    ma_luot_thi, ma_nguoi_dung, ma_phien_ban_de, lan_thi,
    thoi_gian_bat_dau, han_nop_bai, thoi_gian_nop, trang_thai
)
OVERRIDING SYSTEM VALUE VALUES
    -- Lượt thi 1: SV 4 (Khưu Minh Đức) thi Đề giữa kỳ v1 (lần 1) -> Đạt 10.00 điểm
    (1, 4, 1, 1, '2026-09-15 08:00:00+07', '2026-09-15 08:45:00+07', '2026-09-15 08:35:00+07', 'HOAN_TAT'),
    -- Lượt thi 2: SV 5 (Nguyễn Mạnh Dũng) thi Đề giữa kỳ v1 (lần 1) -> Đạt 5.00 điểm
    (2, 5, 1, 1, '2026-09-15 08:05:00+07', '2026-09-15 08:50:00+07', '2026-09-15 08:42:00+07', 'HOAN_TAT'),
    -- Lượt thi 3: SV 5 (Nguyễn Mạnh Dũng) thi lại Đề giữa kỳ v1 (lần 2) -> Đạt 7.50 điểm
    (3, 5, 1, 2, '2026-09-15 14:00:00+07', '2026-09-15 14:45:00+07', '2026-09-15 14:38:00+07', 'HOAN_TAT'),
    -- Lượt thi 4: SV 6 (Trần Thị Ngọc Ánh) thi Đề giữa kỳ v1 (lần 1) -> Đạt 7.50 điểm
    (4, 6, 1, 1, '2026-09-15 09:00:00+07', '2026-09-15 09:45:00+07', '2026-09-15 09:40:00+07', 'HOAN_TAT'),
    -- Lượt thi 5: SV 4 (Khưu Minh Đức) thi Đề cuối kỳ có câu tự luận -> Đang CHO_CHAM
    (5, 4, 3, 1, '2026-10-25 08:00:00+07', '2026-10-25 09:00:00+07', '2026-10-25 08:52:00+07', 'CHO_CHAM'),
    -- Lượt thi 6: SV 7 (Lê Hoàng Nam) đang làm bài Đề giữa kỳ v2 -> DANG_LAM (chưa nộp)
    (6, 7, 2, 1, '2026-11-11 09:30:00+07', '2026-11-11 10:15:00+07', NULL,                     'DANG_LAM');

-- ---------------------------------------------------------------------
-- 14. Bảng CAUTRALOI
-- ---------------------------------------------------------------------
INSERT INTO cau_tra_loi (
    ma_cau_tra_loi, ma_luot_thi, ma_chi_tiet_de,
    noi_dung_tu_luan, lan_cap_nhat, thoi_gian_cap_nhat
)
OVERRIDING SYSTEM VALUE VALUES
    -- Bài làm Lượt thi 1 (SV 4 - Đúng cả 4 câu của Đề 1)
    (1,  1, 1, NULL, 1, '2026-09-15 08:10:00+07'),
    (2,  1, 2, NULL, 1, '2026-09-15 08:18:00+07'),
    (3,  1, 3, NULL, 2, '2026-09-15 08:25:00+07'),
    (4,  1, 4, NULL, 1, '2026-09-15 08:33:00+07'),

    -- Bài làm Lượt thi 2 (SV 5 lần 1 - Đúng câu 1, 2; Sai câu 3, 4 do chọn thiếu đáp án)
    (5,  2, 1, NULL, 1, '2026-09-15 08:12:00+07'),
    (6,  2, 2, NULL, 1, '2026-09-15 08:20:00+07'),
    (7,  2, 3, NULL, 1, '2026-09-15 08:30:00+07'),
    (8,  2, 4, NULL, 1, '2026-09-15 08:40:00+07'),

    -- Bài làm Lượt thi 3 (SV 5 lần 2 - Đúng câu 1, 2, 3; Sai câu 4 do chọn thừa đáp án sai)
    (9,  3, 1, NULL, 1, '2026-09-15 14:10:00+07'),
    (10, 3, 2, NULL, 1, '2026-09-15 14:18:00+07'),
    (11, 3, 3, NULL, 1, '2026-09-15 14:28:00+07'),
    (12, 3, 4, NULL, 2, '2026-09-15 14:36:00+07'),

    -- Bài làm Lượt thi 4 (SV 6 - Đúng câu 1, 3, 4; Sai câu 2)
    (13, 4, 1, NULL, 1, '2026-09-15 09:10:00+07'),
    (14, 4, 2, NULL, 1, '2026-09-15 09:20:00+07'),
    (15, 4, 3, NULL, 1, '2026-09-15 09:30:00+07'),
    (16, 4, 4, NULL, 1, '2026-09-15 09:38:00+07'),

    -- Bài làm Lượt thi 5 (SV 4 thi Đề cuối kỳ - 2 câu trắc nghiệm + 1 câu tự luận)
    (17, 5, 9,  NULL, 1, '2026-10-25 08:15:00+07'),
    (18, 5, 10, NULL, 1, '2026-10-25 08:25:00+07'),
    (19, 5, 11, 'Em thiết kế giao dịch nộp bài dùng SELECT ... FOR UPDATE trên bảng luot_thi để khóa dòng, kiểm tra trang_thai = DANG_LAM rồi mới cập nhật trạng thái và ghi nhận vào bảng ket_qua có UNIQUE(ma_luot_thi).', 3, '2026-10-25 08:50:00+07'),

    -- Bài làm Lượt thi 6 (SV 7 đang làm dở Đề giữa kỳ v2)
    (20, 6, 5, NULL, 2, '2026-11-11 09:40:00+07'),
    (21, 6, 6, NULL, 1, '2026-11-11 09:45:00+07');

-- ---------------------------------------------------------------------
-- 15. Bảng LUACHONTRALOI
-- ---------------------------------------------------------------------
INSERT INTO lua_chon_tra_loi (ma_cau_tra_loi, ma_phuong_an) VALUES
    -- Lượt thi 1 (SV 4): Câu 1 chọn PA 1; Câu 2 chọn PA 10; Câu 3 chọn PA 13, 14; Câu 4 chọn PA 17, 19
    (1, 1),
    (2, 10),
    (3, 13), (3, 14),
    (4, 17), (4, 19),

    -- Lượt thi 2 (SV 5 lần 1): Câu 1 chọn PA 1; Câu 2 chọn PA 10; Câu 3 chỉ chọn PA 13 (thiếu 14); Câu 4 chỉ chọn PA 17 (thiếu 19)
    (5, 1),
    (6, 10),
    (7, 13),
    (8, 17),

    -- Lượt thi 3 (SV 5 lần 2): Câu 1 chọn PA 1; Câu 2 chọn PA 10; Câu 3 chọn PA 13, 14; Câu 4 chọn PA 17, 18, 19 (thừa PA 18 sai)
    (9,  1),
    (10, 10),
    (11, 13), (11, 14),
    (12, 17), (12, 18), (12, 19),

    -- Lượt thi 4 (SV 6): Câu 1 chọn PA 1; Câu 2 chọn PA 9 (sai); Câu 3 chọn PA 13, 14; Câu 4 chọn PA 17, 19
    (13, 1),
    (14, 9),
    (15, 13), (15, 14),
    (16, 17), (16, 19),

    -- Lượt thi 5 (SV 4 - Đề cuối kỳ): Câu 1 (v2) chọn PA 6 (đúng); Câu 2 chọn PA 13, 14 (đúng)
    (17, 6),
    (18, 13), (18, 14),

    -- Lượt thi 6 (SV 7 - Đang làm): Câu 1 (v2) chọn PA 6; Câu 2 chọn PA 10
    (20, 6),
    (21, 10);

-- ---------------------------------------------------------------------
-- 16. Bảng CHITIETCHAM
-- ---------------------------------------------------------------------
INSERT INTO chi_tiet_cham (
    ma_chi_tiet_cham, ma_cau_tra_loi, diem_dat_duoc,
    trang_thai_cham, ma_nguoi_cham, thoi_gian_cham, nhan_xet
)
OVERRIDING SYSTEM VALUE VALUES
    -- Chấm tự động Lượt thi 1 (Tổng 10.00)
    (1,  1,  2.50, 'DA_CHAM', NULL, '2026-09-15 08:35:01+07', 'Chấm tự động: Đúng'),
    (2,  2,  2.50, 'DA_CHAM', NULL, '2026-09-15 08:35:01+07', 'Chấm tự động: Đúng'),
    (3,  3,  2.50, 'DA_CHAM', NULL, '2026-09-15 08:35:01+07', 'Chấm tự động: Đúng toàn phần'),
    (4,  4,  2.50, 'DA_CHAM', NULL, '2026-09-15 08:35:01+07', 'Chấm tự động: Đúng toàn phần'),

    -- Chấm tự động Lượt thi 2 (Tổng 5.00)
    (5,  5,  2.50, 'DA_CHAM', NULL, '2026-09-15 08:42:01+07', 'Chấm tự động: Đúng'),
    (6,  6,  2.50, 'DA_CHAM', NULL, '2026-09-15 08:42:01+07', 'Chấm tự động: Đúng'),
    (7,  7,  0.00, 'DA_CHAM', NULL, '2026-09-15 08:42:01+07', 'Chấm tự động: Chọn thiếu đáp án đúng'),
    (8,  8,  0.00, 'DA_CHAM', NULL, '2026-09-15 08:42:01+07', 'Chấm tự động: Chọn thiếu đáp án đúng'),

    -- Chấm tự động Lượt thi 3 (Tổng 7.50)
    (9,  9,  2.50, 'DA_CHAM', NULL, '2026-09-15 14:38:01+07', 'Chấm tự động: Đúng'),
    (10, 10, 2.50, 'DA_CHAM', NULL, '2026-09-15 14:38:01+07', 'Chấm tự động: Đúng'),
    (11, 11, 2.50, 'DA_CHAM', NULL, '2026-09-15 14:38:01+07', 'Chấm tự động: Đúng toàn phần'),
    (12, 12, 0.00, 'DA_CHAM', NULL, '2026-09-15 14:38:01+07', 'Chấm tự động: Chọn thừa phương án sai'),

    -- Chấm tự động Lượt thi 4 (Tổng 7.50)
    (13, 13, 2.50, 'DA_CHAM', NULL, '2026-09-15 09:40:01+07', 'Chấm tự động: Đúng'),
    (14, 14, 0.00, 'DA_CHAM', NULL, '2026-09-15 09:40:01+07', 'Chấm tự động: Chọn sai đáp án'),
    (15, 15, 2.50, 'DA_CHAM', NULL, '2026-09-15 09:40:01+07', 'Chấm tự động: Đúng toàn phần'),
    (16, 16, 2.50, 'DA_CHAM', NULL, '2026-09-15 09:40:01+07', 'Chấm tự động: Đúng toàn phần'),

    -- Chấm Lượt thi 5 (2 câu trắc nghiệm đã chấm tự động, câu 19 tự luận đang CHO_CHAM)
    (17, 17, 3.00, 'DA_CHAM',  NULL, '2026-10-25 08:52:01+07', 'Chấm tự động: Đúng'),
    (18, 18, 3.00, 'DA_CHAM',  NULL, '2026-10-25 08:52:01+07', 'Chấm tự động: Đúng toàn phần'),
    (19, 19, NULL, 'CHO_CHAM', NULL, NULL,                     'Chờ giảng viên chấm thủ công câu tự luận');

-- ---------------------------------------------------------------------
-- 17. Bảng KETQUA (Chỉ ghi nhận cho các lượt thi đã HOAN_TAT - BR22, BR24)
-- ---------------------------------------------------------------------
INSERT INTO ket_qua (ma_ket_qua, ma_luot_thi, tong_diem, thoi_gian_hoan_tat, trang_thai_ket_qua)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 10.00, '2026-09-15 08:35:02+07', 'CHINH_THUC'),
    (2, 2,  5.00, '2026-09-15 08:42:02+07', 'CHINH_THUC'),
    (3, 3,  7.50, '2026-09-15 14:38:02+07', 'CHINH_THUC'),
    (4, 4,  7.50, '2026-09-15 09:40:02+07', 'CHINH_THUC');

-- Đồng bộ lại bộ đếm tự tăng (IDENTITY sequence) cho tất cả các bảng
SELECT setval(pg_get_serial_sequence('nguoi_dung', 'ma_nguoi_dung'), (SELECT MAX(ma_nguoi_dung) FROM nguoi_dung));
SELECT setval(pg_get_serial_sequence('mon_hoc', 'ma_mon_hoc'), (SELECT MAX(ma_mon_hoc) FROM mon_hoc));
SELECT setval(pg_get_serial_sequence('chu_de', 'ma_chu_de'), (SELECT MAX(ma_chu_de) FROM chu_de));
SELECT setval(pg_get_serial_sequence('cau_hoi', 'ma_cau_hoi'), (SELECT MAX(ma_cau_hoi) FROM cau_hoi));
SELECT setval(pg_get_serial_sequence('phien_ban_cau_hoi', 'ma_phien_ban_ch'), (SELECT MAX(ma_phien_ban_ch) FROM phien_ban_cau_hoi));
SELECT setval(pg_get_serial_sequence('phuong_an', 'ma_phuong_an'), (SELECT MAX(ma_phuong_an) FROM phuong_an));
SELECT setval(pg_get_serial_sequence('de_thi', 'ma_de_thi'), (SELECT MAX(ma_de_thi) FROM de_thi));
SELECT setval(pg_get_serial_sequence('phien_ban_de_thi', 'ma_phien_ban_de'), (SELECT MAX(ma_phien_ban_de) FROM phien_ban_de_thi));
SELECT setval(pg_get_serial_sequence('cau_hoi_trong_de', 'ma_chi_tiet_de'), (SELECT MAX(ma_chi_tiet_de) FROM cau_hoi_trong_de));
SELECT setval(pg_get_serial_sequence('luot_thi', 'ma_luot_thi'), (SELECT MAX(ma_luot_thi) FROM luot_thi));
SELECT setval(pg_get_serial_sequence('cau_tra_loi', 'ma_cau_tra_loi'), (SELECT MAX(ma_cau_tra_loi) FROM cau_tra_loi));
SELECT setval(pg_get_serial_sequence('chi_tiet_cham', 'ma_chi_tiet_cham'), (SELECT MAX(ma_chi_tiet_cham) FROM chi_tiet_cham));
SELECT setval(pg_get_serial_sequence('ket_qua', 'ma_ket_qua'), (SELECT MAX(ma_ket_qua) FROM ket_qua));

COMMIT;

-- Truy vấn 1: Thống kê tỷ lệ trả lời đúng theo từng phiên bản câu hỏi và mức độ khó
SELECT 
    ch.ma_cau_hoi,
    pb.ma_phien_ban_ch,
    pb.so_phien_ban,
    ch.loai_cau_hoi,
    pb.muc_do_kho,
    LEFT(pb.noi_dung, 65) || '...' AS tom_tat_noi_dung,
    COUNT(ctc.ma_chi_tiet_cham) AS tong_luot_cham,
    COUNT(ctc.ma_chi_tiet_cham) FILTER (
        WHERE ctc.diem_dat_duoc = chtd.diem_toi_da
    ) AS so_luot_dung_tuyet_doi,
    ROUND(
        100.0 * COUNT(ctc.ma_chi_tiet_cham) FILTER (WHERE ctc.diem_dat_duoc = chtd.diem_toi_da)
        / NULLIF(COUNT(ctc.ma_chi_tiet_cham), 0),
        2
    ) AS ty_le_dung_phan_tram
FROM cau_hoi ch
JOIN phien_ban_cau_hoi pb ON ch.ma_cau_hoi = pb.ma_cau_hoi
JOIN cau_hoi_trong_de chtd ON pb.ma_phien_ban_ch = chtd.ma_phien_ban_ch
JOIN cau_tra_loi ctl ON chtd.ma_chi_tiet_de = ctl.ma_chi_tiet_de
JOIN chi_tiet_cham ctc ON ctl.ma_cau_tra_loi = ctc.ma_cau_tra_loi
WHERE ctc.trang_thai_cham = 'DA_CHAM'
GROUP BY ch.ma_cau_hoi, pb.ma_phien_ban_ch, pb.so_phien_ban, ch.loai_cau_hoi, pb.muc_do_kho, pb.noi_dung
ORDER BY ty_le_dung_phan_tram ASC, ch.ma_cau_hoi ASC;

-- Truy vấn 2: Thống kê phân bố điểm số (Phổ điểm) và xếp hạng thí sinh theo đề thi
WITH ket_qua_cao_nhat_moi_sv AS (
    SELECT 
        dt.ma_de_thi,
        dt.ten_de_thi,
        nd.ma_nguoi_dung,
        nd.ho_ten,
        COUNT(lt.ma_luot_thi) AS so_lan_da_thi,
        MAX(kq.tong_diem) AS diem_cao_nhat
    FROM ket_qua kq
    JOIN luot_thi lt ON kq.ma_luot_thi = lt.ma_luot_thi
    JOIN phien_ban_de_thi pbdt ON lt.ma_phien_ban_de = pbdt.ma_phien_ban_de
    JOIN de_thi dt ON pbdt.ma_de_thi = dt.ma_de_thi
    JOIN nguoi_dung nd ON lt.ma_nguoi_dung = nd.ma_nguoi_dung
    WHERE kq.trang_thai_ket_qua = 'CHINH_THUC'
    GROUP BY dt.ma_de_thi, dt.ten_de_thi, nd.ma_nguoi_dung, nd.ho_ten
)
SELECT 
    ten_de_thi,
    ma_nguoi_dung,
    ho_ten,
    so_lan_da_thi,
    diem_cao_nhat,
    CASE 
        WHEN diem_cao_nhat >= 8.5 THEN 'Giỏi (8.5 - 10)'
        WHEN diem_cao_nhat >= 7.0 THEN 'Khá (7.0 - 8.4)'
        WHEN diem_cao_nhat >= 5.0 THEN 'Trung bình (5.0 - 6.9)'
        ELSE 'Yếu (< 5.0)'
    END AS muc_pho_diem,
    ROUND(AVG(diem_cao_nhat) OVER (PARTITION BY ma_de_thi), 2) AS diem_tb_toan_de,
    DENSE_RANK() OVER (PARTITION BY ma_de_thi ORDER BY diem_cao_nhat DESC) AS xep_hang,
    ROUND((PERCENT_RANK() OVER (PARTITION BY ma_de_thi ORDER BY diem_cao_nhat ASC) * 100)::numeric, 1) AS phan_tram_vuot_qua
FROM ket_qua_cao_nhat_moi_sv
ORDER BY ma_de_thi, xep_hang;

-- Truy vấn 3: Lựa chọn phiên bản câu hỏi mới nhất đã công bố theo chủ đề và mức độ khó để tạo đề thi
SELECT 
    cd.ten_chu_de,
    ch.ma_cau_hoi,
    ch.loai_cau_hoi,
    pb.ma_phien_ban_ch,
    pb.so_phien_ban AS phien_ban_moi_nhat,
    pb.muc_do_kho,
    pb.quy_tac_cham,
    pb.noi_dung,
    (SELECT COUNT(*) FROM phuong_an pa WHERE pa.ma_phien_ban_ch = pb.ma_phien_ban_ch) AS so_phuong_an,
    (SELECT COUNT(*) FROM cau_hoi_trong_de chtd WHERE chtd.ma_phien_ban_ch = pb.ma_phien_ban_ch) AS so_de_da_su_dung
FROM cau_hoi ch
JOIN chu_de cd ON ch.ma_chu_de = cd.ma_chu_de
JOIN phien_ban_cau_hoi pb ON ch.ma_cau_hoi = pb.ma_cau_hoi
WHERE ch.trang_thai = 'HOAT_DONG'
  AND pb.trang_thai_phien_ban = 'DA_CONG_BO'
  AND pb.so_phien_ban = (
      SELECT MAX(pb2.so_phien_ban)
      FROM phien_ban_cau_hoi pb2
      WHERE pb2.ma_cau_hoi = ch.ma_cau_hoi
        AND pb2.trang_thai_phien_ban = 'DA_CONG_BO'
  )
ORDER BY cd.ma_chu_de, pb.muc_do_kho, ch.ma_cau_hoi;

-- Truy vấn 7: Tra cứu các lượt thi có câu hỏi Tự luận đang chờ chấm thủ công kèm điểm tạm tính phần trắc nghiệm
SELECT 
    lt.ma_luot_thi,
    nd.ho_ten AS ten_thi_sinh,
    dt.ten_de_thi,
    lt.trang_thai AS trang_thai_luot_thi,
    ctl.ma_cau_tra_loi,
    pb.noi_dung AS cau_hoi_tu_luan,
    pb.huong_dan_cham,
    ctl.noi_dung_tu_luan AS bai_lam_cua_thi_sinh,
    chtd.diem_toi_da AS diem_toi_da_tu_luan,
    -- Tổng điểm các câu trắc nghiệm đã chấm xong của lượt thi này
    (
        SELECT COALESCE(SUM(ctc2.diem_dat_duoc), 0)
        FROM cau_tra_loi ctl2
        JOIN chi_tiet_cham ctc2 ON ctl2.ma_cau_tra_loi = ctc2.ma_cau_tra_loi
        WHERE ctl2.ma_luot_thi = lt.ma_luot_thi
          AND ctc2.trang_thai_cham = 'DA_CHAM'
    ) AS diem_trac_nghiem_da_cham
FROM luot_thi lt
JOIN nguoi_dung nd ON lt.ma_nguoi_dung = nd.ma_nguoi_dung
JOIN phien_ban_de_thi pbdt ON lt.ma_phien_ban_de = pbdt.ma_phien_ban_de
JOIN de_thi dt ON pbdt.ma_de_thi = dt.ma_de_thi
JOIN cau_tra_loi ctl ON lt.ma_luot_thi = ctl.ma_luot_thi
JOIN cau_hoi_trong_de chtd ON ctl.ma_chi_tiet_de = chtd.ma_chi_tiet_de
JOIN phien_ban_cau_hoi pb ON chtd.ma_phien_ban_ch = pb.ma_phien_ban_ch
JOIN chi_tiet_cham ctc ON ctl.ma_cau_tra_loi = ctc.ma_cau_tra_loi
WHERE lt.trang_thai = 'CHO_CHAM'
  AND ctc.trang_thai_cham = 'CHO_CHAM';

  -- =====================================================================
-- 5.5.1. HÀM TÍNH ĐIỂM TỰ ĐỘNG CÂU HỎI TRẮC NGHIỆM (BR23)
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_tinh_diem_trac_nghiem(p_ma_cau_tra_loi BIGINT)
RETURNS NUMERIC(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ma_phien_ban_ch  INTEGER;
    v_diem_toi_da      NUMERIC(5,2);
    v_tong_dap_an_dung INTEGER;
    v_so_chon_dung     INTEGER;
    v_so_chon_sai      INTEGER;
BEGIN
    -- Bước 1: Lấy mã phiên bản câu hỏi và điểm tối đa từ câu hỏi trong đề
    SELECT chtd.ma_phien_ban_ch, chtd.diem_toi_da
    INTO v_ma_phien_ban_ch, v_diem_toi_da
    FROM cau_tra_loi ctl
    JOIN cau_hoi_trong_de chtd ON ctl.ma_chi_tiet_de = chtd.ma_chi_tiet_de
    WHERE ctl.ma_cau_tra_loi = p_ma_cau_tra_loi;

    IF NOT FOUND THEN
        RETURN 0.00;
    END IF;

    -- Bước 2: Đếm tổng số phương án đúng của phiên bản câu hỏi đó
    SELECT COUNT(*)
    INTO v_tong_dap_an_dung
    FROM phuong_an
    WHERE ma_phien_ban_ch = v_ma_phien_ban_ch
      AND la_dap_an_dung = TRUE;

    -- Bước 3: Đếm số phương án đúng và số phương án sai mà thí sinh đã chọn
    SELECT 
        COUNT(*) FILTER (WHERE pa.la_dap_an_dung = TRUE),
        COUNT(*) FILTER (WHERE pa.la_dap_an_dung = FALSE)
    INTO v_so_chon_dung, v_so_chon_sai
    FROM lua_chon_tra_loi lctl
    JOIN phuong_an pa ON lctl.ma_phuong_an = pa.ma_phuong_an
    WHERE lctl.ma_cau_tra_loi = p_ma_cau_tra_loi;

    -- Bước 4: Áp dụng quy tắc chấm TOAN_PHAN (Đúng đủ và không chọn sai)
    IF v_tong_dap_an_dung > 0 
       AND v_so_chon_sai = 0 
       AND v_so_chon_dung = v_tong_dap_an_dung THEN
        RETURN v_diem_toi_da;
    ELSE
        RETURN 0.00;
    END IF;
END;
$$;

-- Kiểm tra câu trả lời số 3 (SV chọn đủ 2/2 ý đúng) và câu số 7 (SV chọn thiếu ý đúng)
SELECT 
    fn_tinh_diem_trac_nghiem(3) AS diem_cau_3_chon_du,
    fn_tinh_diem_trac_nghiem(7) AS diem_cau_7_chon_thieu;
-- Kết quả trả về: diem_cau_3_chon_du = 2.50 | diem_cau_7_chon_thieu = 0.00

-- =====================================================================
-- 5.5.2. THỦ TỤC CHẤM ĐIỂM TỰ LUẬN VÀ CHỐT KẾT QUẢ LƯỢT THI (BR22, BR24)
-- =====================================================================
CREATE OR REPLACE PROCEDURE sp_cham_tu_luan_va_chot_ket_qua(
    p_ma_cau_tra_loi BIGINT,
    p_ma_nguoi_cham  INTEGER,
    p_diem_cham      NUMERIC(5,2),
    p_nhan_xet       TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ma_luot_thi     BIGINT;
    v_diem_toi_da     NUMERIC(5,2);
    v_so_cau_cho_cham INTEGER;
    v_tong_diem       NUMERIC(7,2);
BEGIN
    -- Bước 1: Lấy mã lượt thi và điểm tối đa của câu hỏi
    SELECT ctl.ma_luot_thi, chtd.diem_toi_da
    INTO v_ma_luot_thi, v_diem_toi_da
    FROM cau_tra_loi ctl
    JOIN cau_hoi_trong_de chtd ON ctl.ma_chi_tiet_de = chtd.ma_chi_tiet_de
    WHERE ctl.ma_cau_tra_loi = p_ma_cau_tra_loi;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy câu trả lời mã %', p_ma_cau_tra_loi;
    END IF;

    -- Bước 2: Kiểm tra điểm chấm không vượt quá điểm tối đa (Mục 3.2.3 & 4.7.2)
    IF p_diem_cham < 0 OR p_diem_cham > v_diem_toi_da THEN
        RAISE EXCEPTION 'Điểm chấm (%) không hợp lệ! Phải nằm trong khoảng từ 0 đến %.',
            p_diem_cham, v_diem_toi_da;
    END IF;

    -- Bước 3: Cập nhật kết quả chấm thủ công vào bảng chi_tiet_cham
    UPDATE chi_tiet_cham
    SET diem_dat_duoc   = p_diem_cham,
        trang_thai_cham = 'DA_CHAM',
        ma_nguoi_cham   = p_ma_nguoi_cham,
        thoi_gian_cham  = now(),
        nhan_xet        = p_nhan_xet
    WHERE ma_cau_tra_loi = p_ma_cau_tra_loi;

    -- Bước 4: Kiểm tra xem lượt thi này còn câu nào đang CHO_CHAM hay không
    SELECT COUNT(*)
    INTO v_so_cau_cho_cham
    FROM cau_tra_loi ctl
    JOIN chi_tiet_cham ctc ON ctl.ma_cau_tra_loi = ctc.ma_cau_tra_loi
    WHERE ctl.ma_luot_thi = v_ma_luot_thi
      AND ctc.trang_thai_cham = 'CHO_CHAM';

    -- Bước 5: Nếu tất cả các câu đã chấm xong, tổng hợp điểm vào bảng ket_qua
    IF v_so_cau_cho_cham = 0 THEN
        SELECT COALESCE(SUM(ctc.diem_dat_duoc), 0)
        INTO v_tong_diem
        FROM cau_tra_loi ctl
        JOIN chi_tiet_cham ctc ON ctl.ma_cau_tra_loi = ctc.ma_cau_tra_loi
        WHERE ctl.ma_luot_thi = v_ma_luot_thi;

        INSERT INTO ket_qua (ma_luot_thi, tong_diem, thoi_gian_hoan_tat, trang_thai_ket_qua)
        VALUES (v_ma_luot_thi, v_tong_diem, now(), 'CHINH_THUC')
        ON CONFLICT (ma_luot_thi) DO UPDATE
        SET tong_diem          = EXCLUDED.tong_diem,
            thoi_gian_hoan_tat = now();

        UPDATE luot_thi
        SET trang_thai = 'HOAN_TAT'
        WHERE ma_luot_thi = v_ma_luot_thi;
    END IF;
END;
$$;

-- Chấm câu tự luận (ma_cau_tra_loi = 19) của Lượt thi 5 (Khưu Minh Đức) với mức điểm 3.50/4.00
CALL sp_cham_tu_luan_va_chot_ket_qua(
    19, 
    2, 
    3.50, 
    'Trình bày đúng cơ chế SELECT FOR UPDATE và ràng buộc UNIQUE kết quả.'
);

-- Kiểm tra: Lượt thi 5 đã tự động chuyển sang HOAN_TAT và có tổng điểm 9.50 (3.0 + 3.0 + 3.5)
SELECT lt.ma_luot_thi, lt.trang_thai, kq.tong_diem, kq.trang_thai_ket_qua
FROM luot_thi lt
JOIN ket_qua kq ON lt.ma_luot_thi = kq.ma_luot_thi
WHERE lt.ma_luot_thi = 5;

-- =====================================================================
-- 5.5.3. TRIGGER BẢO TOÀN PHIÊN BẢN CÂU HỎI ĐÃ CÔNG BỐ (BR04)
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_trg_bao_toan_phien_ban_cau_hoi()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.trang_thai_phien_ban = 'DA_CONG_BO' THEN
        IF TG_OP = 'DELETE' THEN
            RAISE EXCEPTION 'Không được phép xóa phiên bản câu hỏi (Mã PB = %) đã công bố!',
                OLD.ma_phien_ban_ch;
        ELSIF TG_OP = 'UPDATE' AND (
            NEW.noi_dung IS DISTINCT FROM OLD.noi_dung OR
            NEW.muc_do_kho IS DISTINCT FROM OLD.muc_do_kho OR
            NEW.quy_tac_cham IS DISTINCT FROM OLD.quy_tac_cham OR
            NEW.huong_dan_cham IS DISTINCT FROM OLD.huong_dan_cham
        ) THEN
            RAISE EXCEPTION 'Phiên bản câu hỏi (Mã PB = %) đã công bố và không thể thay đổi! Vui lòng tạo phiên bản mới (so_phien_ban + 1).',
                OLD.ma_phien_ban_ch;
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bao_toan_phien_ban_cau_hoi ON phien_ban_cau_hoi;
CREATE TRIGGER trg_bao_toan_phien_ban_cau_hoi
BEFORE UPDATE OR DELETE ON phien_ban_cau_hoi
FOR EACH ROW
EXECUTE FUNCTION fn_trg_bao_toan_phien_ban_cau_hoi();

-- Thử sửa trực tiếp nội dung của Phiên bản câu hỏi số 1 (đã công bố và đã thi) -> Sẽ bị Trigger chặn ngay!
UPDATE phien_ban_cau_hoi
SET noi_dung = 'Nội dung bị sửa trái phép sau kỳ thi'
WHERE ma_phien_ban_ch = 1;

-- =====================================================================
-- 5.5.4. TRIGGER KIỂM SOÁT CÂU TRẢ LỜI & CHẶN GHI ĐÈ SAU KHI NỘP (BR15, BR17, BR18)
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_trg_kiem_soat_cau_tra_loi()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_trang_thai_luot_thi VARCHAR(15);
    v_pb_de_luot_thi      INTEGER;
    v_pb_de_cau_hoi       INTEGER;
BEGIN
    -- Bước 1: Lấy trạng thái và mã phiên bản đề thi của lượt thi
    SELECT trang_thai, ma_phien_ban_de
    INTO v_trang_thai_luot_thi, v_pb_de_luot_thi
    FROM luot_thi
    WHERE ma_luot_thi = NEW.ma_luot_thi;

    -- Bước 2: Chặn chỉnh sửa nếu lượt thi không còn ở trạng thái DANG_LAM 
    IF v_trang_thai_luot_thi <> 'DANG_LAM' THEN
        RAISE EXCEPTION 'Lượt thi (Mã = %) đã ở trạng thái %, không được phép lưu hoặc ghi đè câu trả lời!',
            NEW.ma_luot_thi, v_trang_thai_luot_thi;
    END IF;

    -- Bước 3: Kiểm tra câu hỏi trả lời phải thuộc đúng phiên bản đề của lượt thi 
    SELECT ma_phien_ban_de
    INTO v_pb_de_cau_hoi
    FROM cau_hoi_trong_de
    WHERE ma_chi_tiet_de = NEW.ma_chi_tiet_de;

    IF v_pb_de_luot_thi <> v_pb_de_cau_hoi THEN
        RAISE EXCEPTION 'Câu hỏi trong đề (Mã = %) không thuộc phiên bản đề thi của lượt thi (Mã = %)!',
            NEW.ma_chi_tiet_de, NEW.ma_luot_thi;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_kiem_soat_cau_tra_loi ON cau_tra_loi;
CREATE TRIGGER trg_kiem_soat_cau_tra_loi
BEFORE INSERT OR UPDATE ON cau_tra_loi
FOR EACH ROW
EXECUTE FUNCTION fn_trg_kiem_soat_cau_tra_loi();

-- Thử cập nhật câu trả lời của Lượt thi số 1 (đã HOAN_TAT) -> Trigger sẽ chặn ngay để bảo vệ bài đã nộp!
UPDATE cau_tra_loi
SET lan_cap_nhat = lan_cap_nhat + 1
WHERE ma_cau_tra_loi = 1;