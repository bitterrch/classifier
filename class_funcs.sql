drop function create_class;

/* ФУНКЦИЯ: создание класса*/
/* ВХОД: name_ - имя класса, parent_id_ - идентификатор родителя, measure_unit_id - идентификатор ЕИ */
/* ВЫХОД: 0 - ошибка
 * -1 - ошибка, добавление в непустую таблицу класса без родителя ИЛИ добавление класса с родителем в пустую таблицу
 * -2 - ошибка, нет такой ЕИ
 * 1 - успешно*/
/* ЭФФЕКТЫ: если measure_unit_id = null, то классу будет назначена ЕИ класса-родителя */

create function create_class(
	name_ varchar(96),
	parent_id_ int,
	measure_unit_id_ int
) returns int language plpgsql as $$
	declare
		id_ int;
		p_id_ int;
		mu_id_ int;
	begin
		if ((parent_id_ is null) and ((select count(*) from classifier) > 0) or 
		(parent_id_ is not null and parent_id_ <> 0) and ((select count(*) from classifier) = 0)) then
			return -1;
		end if;
	
		if (measure_unit_id_ is not null) and (measure_unit_id_ <> 0) then
			select id from measure_unit where id = measure_unit_id_ into mu_id_;
			if mu_id_ is null then
				return -2;
			end if;
		end if;
	
		select id from classifier where name = name_ into id_;
		if ((parent_id_ is null or parent_id_ = 0) and ((select count(*) from classifier) = 0)) or 
		((parent_id_ is not null) and ((select count(*) from classifier) > 0) and (id_ is null)) then
			if (measure_unit_id_ is null) or (measure_unit_id_ = 0) then 
				select measure_unit_id from classifier where id = parent_id_ into mu_id_;
			end if;
			
			if (parent_id_ = 0) then
				insert into classifier (name, parent_id, measure_unit_id) values (name_, null, mu_id_);
			
			else
				insert into classifier (name, parent_id, measure_unit_id) values (name_, parent_id_, mu_id_);
			end if;
			return 1;
		else 
			return 0;
		end if;	
	end;
$$;


drop function delete_class;

/* ФУНКЦИЯ: удаление класса */
/* ВХОД:  id_ - идентификатор класса*/
/* ВЫХОД:  0 - ошибка, -1 - ошибка, такого класса нет, 1 - успешно */
/* ЭФФЕКТЫ: если у класса есть потомки, то перед его удалением им в качестве родителя будет назначен класс-родитель удаляемого класса */

create function delete_class (
	id_ int
) returns int language plpgsql as $$
	declare
		p_id_ int;
	begin
		if ((select count(*) from classifier where id = id_) = 0) then
			return -1;
		end if;
	
		if ((select count(*) from classifier where parent_id = id_) = 0) and 
			((select count(*) from product where class_id = id_) = 0)
		then 
			delete from classifier where id = id_;
			return 1;
		else
			select parent_id from classifier where id = id_ into p_id_;
			if (select count(*) from classifier where parent_id = id_) > 0 then 
				update classifier 
				set parent_id = p_id_
				where parent_id = id_;
			end if;
			if (select count(*) from product where class_id = id_) > 0 then 
				update product 
				set class_id = p_id_
				where class_id = id_;
			end if;
			delete from classifier where id = id_;
			return 1;
		end if;
		return 0;
	end;
$$;

/* ФУНКЦИЯ: замена родителя у класса */
/* ВХОД: id_ - идентификатор класса, parent_id_ - идентификатор класса родителя */
/* ВЫХОД: -1 - ошибка, такого класса не существует, -2 - ошибка, такого родителя не существует 
 * 0 - ошибка, зацикливание, 1 - успешно*/

create function change_class_parent (
    id_ int,
    parent_id_ int
) returns int language plpgsql as $$
	declare
	p_id_ int;
    begin
    	if ((select count(*) from classifier where id = id_) = 0) then
        	return -1;
        end if;
       
        if ((select count(*) from classifier where id = parent_id_) = 0) then 
       		return -2;
       	end if;
       
       p_id_ = parent_id_;
       
        loop
        	if p_id_ = id_
        	then 
        		return 0;
        	end if;
        
        	if p_id_ is null
        	then
        		exit;
        	end if;
        
        	p_id_ = (select parent_id from classifier where id = p_id_);
        end loop;
       
		update classifier set parent_id = parent_id_ where id = id_;
		return 1;
    end;
$$;

drop function change_class_parent;

/* ФУНКЦИЯ: поиск родителей класса*/
/* ВХОД: id_ - идентификатор класса*/
/* ВЫХОД: cl_id - идентификатор класса, cl_name - имя класса, p_id - идентификатор класса-родителя*/

create function find_class_parents (
	id_ int
) returns table(cl_id int, cl_name varchar(96), p_id int) language plpgsql as $$
	begin
		return query
		select classifier.id, classifier.name, classifier.parent_id
		from classifier where id = id_
		union 
		(with recursive r as (
			with t as (select parent_id as parent from classifier where id = id_)
			select classifier.id, classifier.name, classifier.parent_id
			from classifier, t
			where id = t.parent
			union
			select classifier.id, classifier.name, classifier.parent_id
			from classifier join r on classifier.id = r.parent_id
			)
			select * from r)
		order by id desc;
	end;
$$;

drop function find_class_parents;
