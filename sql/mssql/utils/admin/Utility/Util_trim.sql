CREATE FUNCTION DBO.Util_TRIM(@STR NVARCHAR(MAX))
    RETURNS NVARCHAR(MAX)
BEGIN
    declare @TAB nvarchar(2), @LF nvarchar(2), @CR nvarchar(2), @NL nvarchar(2)
    
    set @TAB = char(9)
    set @LF = char(10)
    set @CR = char(13)
    set @NL = char(13)+char(10)
    
    return replace(replace(replace(replace(LTRIM(RTRIM(@STR)), @TAB, ''), @NL, ''), @LF, ''), @CR, '');

END

