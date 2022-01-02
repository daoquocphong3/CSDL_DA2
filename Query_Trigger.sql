USE CONCUNG
GO

--1 Danh sach san pham theo gia tang, giam, loai san pham
--- theo gia tang
SELECT* FROM SANPHAM ORDER BY GIABAN ASC
--- theo gia giam
SELECT* FROM SANPHAM ORDER BY GIABAN DESC
--- theo loai san pham
SELECT* FROM SANPHAM ORDER BY MALOAI

--2 Xuat don hang lap trong nam 2020
SELECT* FROM DONHANG WHERE YEAR(NGAYLAP) = 2020

--3 Xuat SANPHAM ton kho nhieu nhat cua cua hang
--GO
--DROP PROC MAX_STOCK
--DROP PROC MIN_STOCK

GO 
CREATE PROC MAX_STOCK @MACH CHAR(10)
AS BEGIN
	SELECT TOP (10) MASP, SL
		FROM (SELECT KHO.MASP, SUM(SOLUONGTON) AS SL
			FROM KHO, CUAHANG CH
			WHERE CH.MACUAHANG = @MACH AND CH.MACUAHANG = KHO.MACUAHANG
			GROUP BY KHO.MASP ) AS RESULT
	ORDER BY SL DESC 
END
GO

GO
CREATE PROC MIN_STOCK @MACH CHAR(10)
AS BEGIN
	SELECT TOP (10) MASP, SL
		FROM (SELECT KHO.MASP, SUM(SOLUONGTON) AS SL
			FROM KHO, CUAHANG CH
			WHERE CH.MACUAHANG = @MACH AND CH.MACUAHANG = KHO.MACUAHANG
			GROUP BY KHO.MASP ) AS RESULT
	ORDER BY SL 
END
GO


--GO
--DROP PROC MOST_STOCK
GO
CREATE PROC MOST_STOCK @MACH CHAR(10), @MAX BIT
AS BEGIN	
	IF @MAX = 1
	BEGIN
		EXEC MAX_STOCK @MACH
	END
	ELSE
	BEGIN
		EXEC MIN_STOCK @MACH
	END
END
GO

-- MIN = 0, MAX = 1
EXEC MOST_STOCK CH7, 1
GO

--4 Xuat danh sach cua hang co chi tieu cao nhat
SELECT* FROM CUAHANG WHERE CHITIEU = (SELECT MAX(CHITIEU) FROM CUAHANG)

--5 Xuat danh sach 1000 khach hang tong gia tri hoa don cao nhat
SELECT TOP (1000) kh.DIACHI, kh.HOTEN, kh.MAKH, kh.SDT , dh.TONGTIEN
FROM KHACHHANG kh, DONHANG dh
WHERE kh.MAKH = dh.MAKH 
ORDER BY TONGTIEN DESC

--6 Xuat danh sach luong cua nhan vien
SELECT MANV, HOTEN, LUONG FROM NHANVIEN

--7 Xuat danh sach nv dat chi tieu
SELECT * FROM NHANVIEN
WHERE DOANHSO >= CHITIEU


--8 xuat danh sach ch dat chi tieu
SELECT * FROM CUAHANG
WHERE DOANHSO >= CHITIEU

--9 xuat san pham ban chay nhat 
--DROP PROC MAX_SP

GO
CREATE PROC MAX_SP @MACH CHAR(10), @YEAR INT
AS BEGIN
	SELECT TOP (10) MASP, SUM(CT.SOLUONG) AS SL
	FROM CUAHANG CH, NHANVIEN NV, DONHANG DH, CT_DONHANG CT
	WHERE YEAR(DH.NGAYLAP) >= @YEAR AND CH.MACUAHANG = NV.MACUAHANG 
		AND NV.MANV = DH.NVLAPDH AND DH.MADH = CT.MADH 
	GROUP BY MASP 
	ORDER BY SL DESC
END 
GO

--DROP PROC MIN_SP

GO
CREATE PROC MIN_SP @MACH CHAR(10), @YEAR INT
AS BEGIN
	SELECT TOP (10) MASP, SUM(CT.SOLUONG) AS SL
	FROM CUAHANG CH, NHANVIEN NV, DONHANG DH, CT_DONHANG CT
	WHERE YEAR(DH.NGAYLAP) >= @YEAR AND CH.MACUAHANG = NV.MACUAHANG 
		AND NV.MANV = DH.NVLAPDH AND DH.MADH = CT.MADH 
	GROUP BY MASP 
	ORDER BY SL 
END 
GO

--DROP PROC MOST_SP 
GO

CREATE PROC MOST_SP @MACH CHAR(10), @YEAR INT, @MAX BIT = 1
AS BEGIN
	IF @MAX = 1
		EXEC MAX_SP @MACH, @YEAR
	ELSE 
		EXEC MIN_SP @MACH, @YEAR
END
GO

EXEC MOST_SP CH2, 2020
GO



--trigger CT_DONHANG
GO
CREATE TRIGGER CT_DH ON CT_DONHANG
FOR INSERT, UPDATE AS
BEGIN
	declare @COUNT INT = 0
	SELECT @COUNT=COUNT(*) 
	FROM SANPHAM SP INNER JOIN INSERTED INS ON SP.MASP = INS.MASP
	WHERE INS.THANHTIEN != INS.SOLUONG * SP.GIABAN
	IF(@COUNT>0)
	BEGIN
		ROLLBACK TRAN
    		PRINT'THANH TIEN KHONG BANG SOLUONG*GIABAN'
    END
END
GO



--TRIGGER DONHANG

--INSERT DONHANG
--DROP TRIGGER INSERT_DH
GO
CREATE TRIGGER INSERT_DH ON DONHANG
FOR INSERT AS
BEGIN
	IF (0 != (SELECT COUNT(*)
		FROM INSERTED I
		WHERE I.TIENHANG != 0))
	BEGIN
		ROLLBACK TRAN
			PRINT 'TIEN HANG CUA DON HANG PHAI BANG 0 TRONG LUC INSERT'
	END
	IF (0 != (SELECT COUNT(*)
		FROM INSERTED I
		WHERE PHIVANCHUYEN != TONGTIEN))
	BEGIN
		ROLLBACK TRAN
			PRINT 'TONG TIEN CUA DON HANG PHAI BANG PHI VAN CHUYEN TRONG LUC INSERT'
	END
	
END	
GO

INSERT INTO DONHANG VALUES('DH01','KH1', 0, 1, 1, 'NV1000', '2020-01-01', 1)

--DROP TRIGGER INSERT_CT_DH_DH 
GO
CREATE TRIGGER INSERT_CT_DH_DH ON CT_DONHANG
FOR INSERT AS 
BEGIN
	UPDATE DH
	SET DH.TIENHANG+= I.THANHTIEN, DH.TONGTIEN = DH.PHIVANCHUYEN + I.THANHTIEN
	FROM DONHANG DH JOIN INSERTED I ON I.MADH = DH.MADH
END
GO

GO

GO
INSERT INTO CT_DONHANG VALUES('DH01', 'SP1', 1, 358294)

GO


--UPDATE 
--DROP TRIGGER UPDATE_CT_DH_DH
GO
CREATE TRIGGER UPDATE_CT_DH_DH ON CT_DONHANG
FOR UPDATE AS
BEGIN
	UPDATE DH 
	SET DH.TIENHANG += (I.THANHTIEN - D.THANHTIEN),
		DH.TONGTIEN = DH.TIENHANG + DH.PHIVANCHUYEN + I.THANHTIEN - D.THANHTIEN
	FROM DONHANG DH, INSERTED I, DELETED D
	WHERE DH.MADH = I.MADH AND I.MADH = D.MADH
END
GO

UPDATE CT_DONHANG
SET CT_DONHANG.SOLUONG = 2, CT_DONHANG.THANHTIEN *=2
WHERE CT_DONHANG.MADH = 'DH01'

--DELETE
--DROP TRIGGER DELETE_CT_DH_DH
--GO
--CREATE TRIGGER DELETE_CT_DH_DH ON CT_DONHANG
--FOR DELETE AS 
--BEGIN
--	UPDATE DH
--	SET DH.TIENHANG -= D.THANHTIEN,
--		DH.TONGTIEN -= D.THANHTIEN
--	FROM DONHANG DH ,DELETED D
--	WHERE DH.MADH = D.MADH
--END
--GO


--SELECT TOP (2)*FROM DONHANG
--SELECT TOP (2) * FROM CT_DONHANG



--DELETE FROM CT_DONHANG
--WHERE CT_DONHANG.MADH = 'DH01'

