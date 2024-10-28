drop table product;
drop table classifier;
drop table measure_unit;

/* создание таблицы единица измерения */

create table measure_unit (
	id serial not null primary key,
	short_name varchar(5),
	name varchar(50) unique,
	code int unique	
);

/* создание таблицы классификатор */

create table classifier (
    id serial not null primary key,
    name varchar(150) unique,
    parent_id int references classifier (id) on delete cascade,
    measure_unit_id int references measure_unit 
);

/* создание таблицы продукт */

create table product (
    id serial not null primary key,
    name varchar (96) unique,
    code int unique,
    class_id int references classifier (id) on delete cascade,
    measure_unit_id int references measure_unit 
);


