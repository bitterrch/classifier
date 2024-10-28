drop function find_cl_cl;

/* ФУНКЦИЯ: Поиск всех подклассов класса*/
/* ВХОД: id_ - идентификатор класса, mode_ - выбор вывода по возрастанию или убыванию*/
/* ВЫХОД: cl_id - идентификатор класса, cl_name - название класса, p_id - идентификатор класса-родителя*/
/* ТРЕБОВАНИЯ: 1. mode_ должен быть равен 'desc' для вывода по убыванию, либо 'asc'/''/null для вывода по возрастанию
 * 			   2. Элемент должен быть в дереве */
/* ЭФФЕКТЫ: 1. Для терминального элемента выдает исходный элемент  
 * 			2. Для элемента, которого нет в дереве, выдаёт пустую строку
 * 			3. Если mode_ введён неверно, то выдаёт пустую строку*/

create function find_cl_cl (
	id_ int,
	mode_ varchar(10)
) returns table (cl_id int, cl_name varchar(96), p_id int, m_u_id int) language plpgsql as $$
	begin
		if mode_ = 'desc' then
			return query
			select classifier.id, classifier.name, classifier.parent_id, classifier.measure_unit_id 
			from classifier where id = id_
			union 
			(with recursive r as (
				select classifier.id, classifier.name, classifier.parent_id, classifier.measure_unit_id 
				from classifier where parent_id = id_
				union
				select classifier.id, classifier.name, classifier.parent_id, classifier.measure_unit_id 
				from classifier join r on classifier.parent_id = r.id
			)
			select * from r)
			order by id desc;
		else
			if mode_ = 'asc' or mode_ is null or mode_ = '' then
				return query
				select classifier.id, classifier.name, classifier.parent_id, classifier.measure_unit_id 
				from classifier where id = id_
				union 
				(with recursive r as (
					select classifier.id, classifier.name, classifier.parent_id, classifier.measure_unit_id 
					from classifier where parent_id = id_
					union
					select classifier.id, classifier.name, classifier.parent_id, classifier.measure_unit_id 
					from classifier join r on classifier.parent_id = r.id
				)
				select * from r)
				order by id;
			else
				return query
					select * from classifier where id = 0;
			end if;				
		end if;
	end;	
$$;

/* ФУНКЦИЯ: Поиск всех продуктов класса*/
/* ВХОД: id_ - идентификатор класса, mode_ - выбор вывода по возрастанию или убыванию*/
/* ВЫХОД: pr_id - идентификатор продукта, pr_name - название продукта, pr_code - код продукта
 * cl_id - идентификатор класса, m_u_id - идентификатор ЕИ */
/* ТРЕБОВАНИЯ: 1. mode_ должен быть равен 'desc' для вывода по убыванию, либо 'asc'/''/null для вывода по возрастанию 
 * 			   2. Элемент должен быть в дереве*/
/* ЭФФЕКТЫ: 1. Для элемента, которого нет в дереве, выдаёт пустую строку
 * 			2. Если mode_ введён неверно, то выдаёт пустую строку*/

create function find_pr_cl(
	id_ int,
	mode_ varchar(5)
) returns table (pr_id int, pr_name varchar(96), pr_code int, cl_id int, m_u_id int) language plpgsql as $$
	begin
		if mode_ = 'desc' then
			return query
			select * from product where class_id = id_
			order by id desc;
		else
			if mode_ = 'asc' or mode_ is null or mode_ = '' then
				return query
				select * from product where class_id = id_;
			else
				return query
				select * from product where id = 0;
			end if;
		end if;
	end;
$$;

/* ФУНКЦИЯ: Вывод всех продуктов выбранного класса */
/* ВХОД: id_ - идентификатор класса*/
/* ВЫХОД: pr_id - идентификатор продукта, pr_name - название продукта, pr_code - код продукта
 * m_u_name - обозначение ЕИ, cl_id - индентификатор класса, cl_name - название класса*/
/* ЭФФЕКТЫ: 1. Для элемента, которого нет в дереве, выдаёт пустую строку*/

create function find_list(
	id_ int
) returns table (pr_id int, pr_name varchar(96), pr_code int, m_u_name varchar(5), cl_id int, cl_name varchar(96))
language plpgsql as $$
	begin
		return query
		with t as (select * from find_cl_cl(id_, 'asc'))
		select product.id, product.name, product.code int, measure_unit.short_name, product.class_id, classifier.name 
		from product
		inner join classifier on classifier.id = product.class_id 
		inner join measure_unit on product.measure_unit_id = measure_unit.id
		where product.class_id = any(select t.cl_id from t);
	end;
$$;

/* ФУНКЦИЯ: Определяет, является ли класс родителем продукта */
/* ВХОД: id_ - идентификатор продукта, class_id_ - идентификатор класса */
/* ВЫХОД: -1 - такого продукта нет, -2 - такого класса нет, 1 - класс является родителем продукта, 0 - не является */

create function is_parent (
	id_ int,
	class_id_ int
) returns integer language plpgsql as $$
	declare
		pr_id_ int;
		cl_id_ int;
	begin
		select count(*) from product where id = id_ into pr_id_;
		if (pr_id_ <> 1) then 
			return -1;
		end if;
	
		select count(*) from classifier where id = class_id_ into cl_id_;
		if (cl_id_ <> 1) then 
			return -2;
		end if;
	
		if class_id_ in (select cl_id from (select * from find_product_parents(id_))) then 
			return 1;
		else 
			return 0;
		end if;
	
	end;	
$$;

drop function is_parent;

