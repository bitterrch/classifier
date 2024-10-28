drop function create_product;

/* ФУНКЦИЯ: создание продукта */
/* ВХОД: name_ - имя продукта, code_ - код продукта, measure_unit_id_ - идентификатор ЕИ, class_id_ - идентификатор класса */
/* ВЫХОД: -1 - ошибка, продукт с таким кодом уже есть, -2 - ошибка, такой ЕИ не существует
 * -3 - ошибка, такого класса не существует, -4 - ошибка, продукт с таким именем уже есть
 * 1 - успешно*/
/* ЭФФЕКТЫ: если measure_unit_id = null, то продукту будет назначена ЕИ родителя */

create function create_product(
	name_ varchar(96),
	code_ int,
	class_id_ int,
	measure_unit_id_ int
) returns int language plpgsql as $$
	declare 
		mu_id_ int;
	begin
		if ((select count(*) from product where code = code_) > 0) then 
			return -1;
		end if;
	
		if ((select count(*) from measure_unit where id = measure_unit_id_) = 0) and ((measure_unit_id_ is not null)
		and (measure_unit_id_ <> 0)) then
			return -2;
		end if;
	
		if ((select count(*) from classifier where id = class_id_) = 0) then 
			return -3;
		end if;
	
		if ((select count(*) from product where name = name_) > 0) then 
			return -4;
		end if;
	
		if (measure_unit_id_ is null) or (measure_unit_id_ = 0) then
			select measure_unit_id from classifier where id = class_id_ into mu_id_;
			insert into product (name, code, class_id, measure_unit_id)
			values (name_, code_, class_id_, mu_id_);
		else
			insert into product (name, code, class_id, measure_unit_id)
			values (name_, code_, class_id_, measure_unit_id_);
		end if;	
	
		return 1;
	
	end;
$$;

/* ФУНКЦИЯ: удаление продукта */
/* ВХОД: id_ - идентификатор продукта*/
/* ВЫХОД: -1 - ошибка, такого продукта нет, 1 - успешно*/

create function delete_product(
	id_ int
) returns int language plpgsql as $$
	begin
		if ((select count(*) from product where id = id_) = 0) then 
			return -1;
		end if;
	
		delete from product where id = id_;
		return 1;
	end;
$$;

/* ФУНКЦИЯ: изменение родителя у продукта */
/* ВХОД:  id_ - идентификатор продукта, class_id_ - идентификатор класса родителя */
/* ВЫХОД: -1 - ошибка, такого продукта не существует, -2 - ошибка, такого класса не существует, 1 - успешно*/

create function change_product_parent(
	id_ int,
	class_id_ int
) returns int language plpgsql as $$
	begin
		if ((select count(*) from product where id = id_) = 0) then 
			return -1;
		end if;
	
		if ((select count(*) from classifier where id = class_id_) = 0) then 
			return -2;
		end if;
	
		update product set class_id = class_id_ where id = id_;
		return 1;
	
	end;
$$;

/* ФУНКЦИЯ: поиск родителей продукта*/
/* ВХОД: id_ - идентификатор продукта*/
/* ВЫХОД: cl_id - идентификатор класса, cl_name - имя класса, p_id - идентификатор класса-родителя*/

create function find_product_parents(
	id_ int
) returns table (cl_id int, cl_name varchar(96), p_id int) language plpgsql as $$
	declare
	class_id_ int;
	begin	
		select class_id from product where id = id_ into class_id_;
		return query
			select * from find_class_parents(class_id_);
	end;
$$;

drop function find_product_parents;


