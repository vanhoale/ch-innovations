create table person (
    id serial primary key,
    name varchar not null,
    email varchar unique not null
);

create type cadence as enum ('Daily','Weekly','Monthly');

create table task (
    id serial primary key,
    name varchar,
    description text
);

create type status as enum ('Not Started','In Progress','Completed');

create table task_occurence (
    id serial primary key,
    task_id int not null,
    recurrence cadence,
    start_date date not null,
    end_date date,
    status status,
    foreign key (task_id) references task(id) on delete cascade
);

create table task_assigment (
    id serial primary key,
    task_id int not null,
    person_id int not null,
    foreign key (task_id) references task(id) on delete cascade,
    foreign key (person_id) references person(id) on delete cascade
);   

insert into person(name, email) values ('Ricardo', 'ricardo@example.com');
insert into person(name, email) values ('Shanaya', 'shanaya@example.com');
insert into person(name, email) values ('Daniel', 'eaniel@example.com');

insert into task(name, description) values('task1', 'monthly, end after 12 occurrences');
insert into task(name, description) values('task2', 'one occurrence');
insert into task(name, description) values('task2', 'daily, end after 30 occurrences');

insert into task_occurence(task_id, recurrence, start_date, end_date, status) values (1, 'Monthly', now(), now() + interval '1 year', 'Not Started');
insert into task_occurence(task_id, recurrence, start_date, end_date, status) values (2, null, now() + interval '1 day', now() + interval '1 day', 'Not Started');
insert into task_occurence(task_id, recurrence, start_date, end_date, status) values (2, null, now() - interval '1 day', now() + interval '29 day', 'In Progress');

insert into task_assigment(task_id, person_id) values (1,1);
insert into task_assigment(task_id, person_id) values (1,2);
insert into task_assigment(task_id, person_id) values (2,2);
insert into task_assigment(task_id, person_id) values (2,3);
