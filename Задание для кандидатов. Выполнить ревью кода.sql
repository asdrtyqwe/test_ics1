create procedure syn.usp_ImportFileCustomerSeasonal
	@ID_Record int
as
set nocount on
-- 1)Перед begin нужна пустая строка
begin
	declare @RowCount int = (select count(*) from syn.SA_CustomerSeasonal)
	/* 2)Все переменные задаются в одном объявлении
	 3)Рекомендуется не использовать длину поля max */
	declare @ErrorMessage varchar(max)

-- Проверка на корректность загрузки
	if not exists (
	select 1
	-- 4)Неправильно написан алиас
	from syn.ImportFile as f
	where f.ID = @ID_Record
		and f.FlagLoaded = cast(1 as bit)
	)
		-- 5)Необходимо ставить пустые строки между логическими блоками
		begin
			set @ErrorMessage = 'Ошибка при загрузке файла, проверьте корректность данных'

			raiserror(@ErrorMessage, 3, 1)
			-- 6)Необходимо ставить пустые строки перед return
			return
		end

	-- 7)CREATE TABLE необходимо написать в нижнем регистре
	CREATE TABLE #ProcessedRows (
		ActionType varchar(255),
		ID int
	)
	-- 8)Необходимо поставить пробел между "--" и комментарием
	--Чтение из слоя временных данных
	select
		cc.ID as ID_dbo_Customer
		,cst.ID as ID_CustomerSystemType
		,s.ID as ID_Season
		,cast(cs.DateBegin as date) as DateBegin
		,cast(cs.DateEnd as date) as DateEnd
		,cd.ID as ID_dbo_CustomerDistributor
		,cast(isnull(cs.FlagActive, 0) as bit) as FlagActive
	into #CustomerSeasonal
	-- 9)Не поставлено as перед алиасом
	from syn.SA_CustomerSeasonal cs
		join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
			and cc.ID_mapping_DataSource = 1
		join dbo.Season as s on s.Name = cs.Season
		join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor
			and cd.ID_mapping_DataSource = 1
		join syn.CustomerSystemType as cst on cs.CustomerSystemType = cst.Name
	where try_cast(cs.DateBegin as date) is not null
		and try_cast(cs.DateEnd as date) is not null
		and try_cast(isnull(cs.FlagActive, 0) as bit) is not null
	
	-- 10)Необходимо писать многострочные комментарии в конструкции /**/
	-- Определяем некорректные записи
	-- Добавляем причину, по которой запись считается некорректной
	select
		cs.*
		-- 11)Конструкция case должен быть с отступом
		,case
			-- 12)Then должно быть с +1 отступом после под when 
			when cc.ID is null then 'UID клиента отсутствует в справочнике "Клиент"'
			when cd.ID is null then 'UID дистрибьютора отсутствует в справочнике "Клиент"'
			when s.ID is null then 'Сезон отсутствует в справочнике "Сезон"'
			when cst.ID is null then 'Тип клиента в справочнике "Тип клиента"'
			when try_cast(cs.DateBegin as date) is null then 'Невозможно определить Дату начала'
			-- 13)По идее, здесь должна быть дата конца, а не начала
			when try_cast(cs.DateEnd as date) is null then 'Невозможно определить Дату начала'
			when try_cast(isnull(cs.FlagActive, 0) as bit) is null then 'Невозможно определить Активность'
		end as Reason
	into #BadInsertedRows
	from syn.SA_CustomerSeasonal as cs
	-- 14)Join вынести на один отступ после from
	left join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
		and cc.ID_mapping_DataSource = 1
	-- 15)Нужно вынести and на один отступ от join
	left join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor and cd.ID_mapping_DataSource = 1
	left join dbo.Season as s on s.Name = cs.Season
	left join syn.CustomerSystemType as cst on cst.Name = cs.CustomerSystemType
	-- 16)Нет пустой строки после join
	where cc.ID is null
		or cd.ID is null
		or s.ID is null
		or cst.ID is null
		or try_cast(cs.DateBegin as date) is null
		or try_cast(cs.DateEnd as date) is null
		or try_cast(isnull(cs.FlagActive, 0) as bit) is null
		
end
