drop function insert_measure_unit;

/* ФУНКЦИЯ: добавление единицы измерения */
/* ВХОД: code_ - международный код ЕИ, short_name_ - обозначение, name_ - имя ЕИ*/
/* ВЫХОД: 0 - ошибка, 1 - успешно*/

create function insert_measure_unit (
	code_ int,
	short_name_ varchar(5),
	name_ varchar(50)
) returns int language plpgsql as $$
	declare 
		id_ int;
	begin
		select id from measure_unit where code = code_ into id_;
		if (id_ is null) and ((select count(*) from measure_unit where name = name_) = 0) then 
			insert into measure_unit (short_name, name, code) 
			values (short_name_, name_, code_);
			return 1;
		else
			return 0;
		end if;	
	end;
$$;

drop function delete_measure_unit;

/* ФУНКЦИЯ: удаление единицы измерения */
/* ВХОД: id_ - идентификатор ЕИ*/
/* ВЫХОД: 0 - ошибка, 1 - успешно, 2 - успешно, но в таблице classifier и/или product ячейка ЕИ стала пустой */

create function delete_measure_unit(
	id_ int
) returns int language plpgsql as $$
	declare
		product_id_ int;
	begin
		select id from product where measure_unit_id = id_ into product_id_;
		if (product_id_ is null) then 
			delete from measure_unit where id = id_;
			return 1;
		else
			update product set measure_unit_id = null where measure_unit_id = id_;
			delete from measure_unit where id = id_;
			return 2;
		return 0;
		end if;
	end;
$$;
