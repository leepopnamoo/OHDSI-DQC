-- ------------------------------ 
-- CDM DQ Script  
-- ------------------------------
-- description :: OHDSI CDM 기본 스키마 및 데이터 점검 SQL입니다. Primary key, Foreign Key 설정등 CDM Doc에서 정의한 
--                기준으로 설정되어 있음을 전제로 하여 점검하게 됩니다. CDM 표준을 따르지 않으면 점검이 정상적으로 되지 않습니다. 
-- create date :: 2022.05 
-- edited date :: 2022.06 
-- DB 정의서 
-- Table 정의서 
-- 컬럼 정의서
-- Domain 정의서 
-- 업무규칙 모집단 기준, 기간 등등 코드 기준. 
-- Schema검증 15개, 개념검증 33개 
-- copywrite@ fingertree@gmail.com  
-- -------------------------------

-- 스키마를 설정하세요 
--@set schema_name = schema name of cdm    
@set schema_name = cdmcloud 

select '${schema_name}';

-- 1. 테이블 칼럼수 1초과 테이블  :: obj_description(oid) 테이블 코멘트 추가 :: 주석은 타이틀과 설명을 |으로 분리 적용
select t.schemaname, t.relname, split_part(obj_description(c.oid), '|', 1) as title, split_part(obj_description(c.oid), '|', 2) as description, t.n_live_tup  
from pg_catalog.pg_stat_user_tables t join pg_catalog.pg_class c on (c.relnamespace::regnamespace::text = t.schemaname and c.relname = t.relname and c.relkind = 'r')
where t.schemaname = '${schema_name}'  
and t.n_live_tup > 1 
order by 3 ;

-- 2. 테이블별 칼럼형식 목록 - table column data type 
select i.table_name, i.ordinal_position, i.column_name, 
       split_part((SELECT col_description(a.attrelid, a.attnum)), '|', 1) AS title, 
       split_part((SELECT col_description(a.attrelid, a.attnum)), '|', 2) AS description, i.is_nullable, i.data_type, i.udt_name    
from information_schema."columns" i join pg_catalog.pg_attribute a on (a.attrelid = i.table_name::regclass::oid and a.attnum = i.ordinal_position)
where i.table_schema = '${schema_name}' 
and exists (select 1 from pg_catalog.pg_stat_user_tables u where i.table_name = u.relname and u.schemaname = i.table_schema
             and u.n_live_tup > 1 )
order by 1, 2;

-- 3. 테이블별 칼럼형식 - Not Null 칼럼 
select i.table_name, i.ordinal_position, i.column_name, 
       split_part((SELECT col_description(a.attrelid, a.attnum)), '|', 1) AS title, 
       split_part((SELECT col_description(a.attrelid, a.attnum)), '|', 2) AS description, i.is_nullable, i.data_type, i.udt_name    
from information_schema."columns" i join pg_catalog.pg_attribute a on (a.attrelid = i.table_name::regclass::oid and a.attnum = i.ordinal_position) 
where i.table_schema = '${schema_name}'
and i.is_nullable = 'NO'
and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema  
             and a.n_live_tup > 1 )
order by 1, 2;

-- 4. 테이블별 칼럼형식 - time or date 칼럼 
select i.table_name, i.ordinal_position, i.column_name, 
       split_part((SELECT col_description(a.attrelid, a.attnum)), '|', 1) AS title, 
       split_part((SELECT col_description(a.attrelid, a.attnum)), '|', 2) AS description, i.is_nullable, i.data_type, i.udt_name     
from information_schema."columns" i join pg_catalog.pg_attribute a on (a.attrelid = i.table_name::regclass::oid and a.attnum = i.ordinal_position)
where i.table_schema = '${schema_name}'
and (i.data_type like 'time%' or i.data_type like 'date%')
and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema 
             and a.n_live_tup > 1 )
order by 1, 2;

-- 5. 데이터 타입별 칼럼 갯수 1 
select i.data_type, i.udt_name, count(1) as totalcnt     
from information_schema."columns" i
where i.table_schema = '${schema_name}'
and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema
             and a.n_live_tup > 1 )
group by 1, 2
order by 3;

-- 6. 데이터 타입별 칼럼 갯수 2
select i.data_type, count(1) as total      
from information_schema."columns" i
where i.table_schema = '${schema_name}'
and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema 
             and a.n_live_tup > 1 )
group by 1 
;

-- 7. 총칼럼갯수 239 
with col as (
	select i.table_name, count(1) as column_count 
	from information_schema."columns" i where i.table_schema = '${schema_name}'
	and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema 
	             and a.n_live_tup > 1 ) 
	GROUP by i.table_name order by column_count desc
)
select sum(column_count) from col;

-- 8. 테이블별 칼럼갯수 데이터 1개 초과  
select i.table_name, count(1) as column_count 
from information_schema."columns" i
where i.table_schema = '${schema_name}' 
and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema
             and a.n_live_tup > 1 )
GROUP by i.table_name order by column_count desc; 

-- 6. 스키마에 사용된 데이터 형식별 칼럼 건수 
select i.data_type, count(1) as total      
from information_schema."columns" i
where i.table_schema = '${schema_name}'
and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema 
             and a.n_live_tup > 1 )
group by 1 
order by 2; 

-- 9. 키, 참조키 리스트 
with pop as (
 SELECT 
    (conrelid::regclass)::varchar AS table_from,
    conname,
    pg_get_constraintdef(oid) as condef,
    r.contype  
 FROM pg_catalog.pg_constraint r
) 
select * from pop where table_from not like '%.%' and table_from != '-' and table_from != 'admin' and table_from not like 'bsct_%'
order by 1 
;

-- 10. 테이블별 건수 산정 
with tbl as (
  select distinct i.table_schema, i.table_name 
  from information_schema."columns" i
  where i.table_schema = '${schema_name}' 
  and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema 
              and a.n_live_tup > 1 )
)
SELECT 
  table_schema, 
  table_name, 
  (xpath('/row/c/text()', 
    query_to_xml(format('select count(*) AS c from %I.%I', table_schema, table_name), 
    false, 
    true, 
    '')))[1]::text::int AS rows_n
FROM tbl ORDER BY 2 
;

-- 11. 테이블별 칼럼형식이 Null이 아닌 데이터 건수 보기 - Not Null 칼럼 
with table_n as (
select i.table_schema, i.table_name, i.ordinal_position, i.column_name, i.is_nullable, i.data_type, i.udt_name    
from information_schema."columns" i
where i.table_schema = '${schema_name}'
and i.is_nullable = 'NO'
and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema 
             and a.n_live_tup > 1 )
order by 1, 2
)
select table_name, column_name,
	(xpath('/row/nullcount/text()', 
      query_to_xml(format('SELECT count(1) as nullcount from %I.%I where %I is null', table_schema, table_name, column_name),false, 
    true, 
    '')))[1]::text::int AS rows_null 
from table_n    
;

-- 12 날짜형식 특정기간 벗어난 건수 구하기  
with table_n as ( 
select i.table_schema, i.table_name, i.ordinal_position, i.column_name, i.is_nullable, i.data_type, i.udt_name    
from information_schema."columns" i
where i.table_schema = '${schema_name}'
and (i.data_type like 'time%' or i.data_type like 'date%')
and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema
             and a.n_live_tup > 1 )
order by 1, 2
)
select table_name, column_name,
	(xpath('/row/total/text()', 
      query_to_xml(format('SELECT count(1) as total from %I.%I where %I <= ''1900.01.01'' or %I >= ''2100.01.01''' , table_schema, table_name, column_name, column_name), false, 
    true, 
    '')))[1]::text::int AS rows_outrange 
from table_n
;

-- 13. 테이블별 칼럼형식 - time or date 칼럼 
with table_n as ( 
select i.table_schema, i.table_name, i.ordinal_position, i.column_name, i.is_nullable, i.data_type, i.udt_name    
from information_schema."columns" i
where i.table_schema = '${schema_name}'
and (i.data_type like 'time%' or i.data_type like 'date%')
and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema
             and a.n_live_tup > 1 )
order by 1, 2
)
select table_name, column_name,
	(xpath('/row/min/text()', 
      query_to_xml(format('SELECT min(%I) from %I.%I' , column_name, table_schema, table_name), false, 
    true, 
    '')))[1]::text::timestamp AS rows_min, 
	(xpath('/row/max/text()', 
      query_to_xml(format('SELECT max(%I) from %I.%I' , column_name, table_schema, table_name), false, 
    true, 
    '')))[1]::text::timestamp AS rows_max,    
	(xpath('/row/total/text()', 
      query_to_xml(format('SELECT count(1) as total from %I.%I where %I <= ''1900.01.01'' or %I >= ''2100.01.01''' , table_schema, table_name, column_name, column_name), false, 
    true, 
    '')))[1]::text::int AS rows_outrange 
from table_n    
;

-- 14. 테이블별 숫자 형식 자료 min max 
with table_n as (
	select i.table_schema, i.table_name, i.ordinal_position, i.column_name, i.is_nullable, i.data_type, i.udt_name    
	from information_schema."columns" i
	where i.table_schema = '${schema_name}'
	and (i.data_type like 'bigint%' or i.data_type like 'int%' or i.data_type like 'numeric%')
	and exists (select 1 from pg_catalog.pg_stat_user_tables a where i.table_name = a.relname and a.schemaname = i.table_schema 
	             and a.n_live_tup > 1 )
	order by 1, 2
)
select table_name, column_name, is_nullable, 
       format('SELECT min(%I) from %I.%I' , column_name, table_schema, table_name) as minSQLsyntax,
       format('SELECT max(%I) from %I.%I' , column_name, table_schema, table_name) as maxSQLsyntax,
	(xpath('/row/min/text()', 
      query_to_xml(format('SELECT min(%I) from %I.%I' , column_name, table_schema, table_name), false, 
    true, 
    '')))[1]::text::numeric AS rows_min,
   	(xpath('/row/max/text()', 
      query_to_xml(format('SELECT max(%I) from %I.%I' , column_name, table_schema, table_name), false, 
    true, 
    '')))[1]::text::numeric AS rows_max
from table_n     
; 

-- 15. 테이블별 참조키 검증 
with pop as (
 SELECT 
    (conrelid::regclass)::varchar AS table_from,
    conname,
    pg_get_constraintdef(oid) as condef,
    r.contype  
 FROM pg_catalog.pg_constraint r
 where r.contype = 'f' 
) 
select 
table_from, conname, 
condef, 
(xpath('/row/fcount/text()', 
      query_to_xml(format('select count(1) as fcount from %I t where not exists (select 1 from %I a where a.%I = t.%I) and t.%I is not null', table_from, 
                           split_part(split_part(condef, 'REFERENCES ', 2), '(', 1), 
                           left(split_part(condef, '(', 3), -1), 
                           split_part(split_part(condef, 'FOREIGN KEY (', 2), ')', 1),
                           split_part(split_part(condef, 'FOREIGN KEY (', 2), ')', 1)), false, 
    true, 
    '')))[1]::text::int AS fcount 
from pop 
where table_from not like '%.%' and table_from != '-' and table_from != 'admin' and table_from not like 'bsct_%' 
order by 1 
;

-- 418개 class 존재 
select * from concept_class where concept_class_id like 'Ope%'
order by 1;

-- 수기검증룰 R001 ~ 
-- R001 
select count(a.gender_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.gender_concept_id and b.concept_class_id = 'Gender') then 1 end) as ruleCheck   
from person a;
-- R002 
select count(a.race_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.race_concept_id and b.concept_class_id = 'Race') then 1 end) as ruleCheck   
from person a;
-- R003 
select count(a.ethnicity_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.ethnicity_concept_id and b.concept_class_id = 'Ethnicity') then 1 end) as ruleCheck   
from person a;
-- R004 :: ETL 적용 필요함 
select gender_concept_id, count(1) from person group by 1;
select gender_source_value, count(1) from person group by 1; 
-- R005 
select count(a.procedure_concept_id) as total, 
       sum(case when a.procedure_concept_id = 0 then 1 else 0 end) as Unmatch, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.procedure_concept_id and b.concept_class_id = 'Procedure') then 1 end) as ruleCheck   
from procedure_occurrence a;
-- R006 
select count(a.procedure_type_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.procedure_type_concept_id and b.concept_class_id = 'Procedure Type') then 1 end) as ruleCheck   
from procedure_occurrence a;
-- R007 
select count(a.provider_id) as total, 
       sum(case when exists (select 1 from provider b where b.provider_id = a.provider_id) then 1 end) as ruleCheck   
from procedure_occurrence a;
-- R008 
select count(a.care_site_id) as total, 
       sum(case when exists (select 1 from care_site b where b.care_site_id = a.care_site_id) then 1 end) as ruleCheck   
from provider a;
-- R009 
select count(a.visit_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.visit_concept_id and b.concept_class_id = 'Visit') then 1 end) as ruleCheck   
from visit_occurrence a;
-- R010 
select count(a.visit_type_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.visit_type_concept_id and b.concept_class_id = 'Visit Type') then 1 end) as ruleCheck   
from visit_occurrence a;
-- R011 'Place Of Service' 표준코드는 별도 존재하지 않기 때문에 Location으로 정의 
select * from concept where concept_id = 4318944 ;
-- R012 
select count(a.domain_id) as total, 
       sum(case when exists (select 1 from domain b where b.domain_id = a.domain_id) then 1 end) as ruleCheck 
from concept a ; 
-- R013 
select count(a.vocabulary_id) as total, 
       sum(case when exists (select 1 from vocabulary b where b.vocabulary_id = a.vocabulary_id) then 1 end) as ruleCheck 
from concept a ; 
-- R014 
select count(a.concept_class_id) as total, 
       sum(case when exists (select 1 from concept_class b where b.concept_class_id = a.concept_class_id) then 1 end) as ruleCheck 
from concept a ; 
-- R015 
select count(a.condition_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.condition_concept_id and b.domain_id = 'Condition') then 1 end) as ruleCheck 
from condition_era a ; 
-- R016 
select count(a.condition_type_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.condition_type_concept_id and b.concept_class_id = 'Condition Type') then 1 end) as ruleCheck 
from condition_occurrence a ; 
-- R017 
select count(a.condition_status_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.condition_status_concept_id and b.concept_class_id = 'Condition Status') then 1 end) as ruleCheck 
from condition_occurrence a ; 
-- R018 
select count(a.death_type_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.death_type_concept_id and b.concept_class_id = 'Death Type') then 1 end) as ruleCheck 
from death a ; 
-- R019 
select count(a.drug_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.drug_concept_id and b.domain_id = 'Drug') then 1 end) as ruleCheck 
from dose_era a ; 
-- R020 
select count(a.unit_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.unit_concept_id and b.concept_class_id = 'Unit') then 1 end) as ruleCheck 
from dose_era a ; 
-- R021 
select count(a.drug_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.drug_concept_id and b.domain_id = 'Drug') then 1 end) as ruleCheck 
from drug_era a ; 
-- R022 
select count(a.drug_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.drug_concept_id and b.domain_id = 'Drug') then 1 end) as ruleCheck 
from drug_exposure a ;
-- R023 
select count(a.drug_type_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.drug_type_concept_id and b.concept_class_id = 'Drug Type') then 1 end) as ruleCheck   
from drug_exposure a;
-- R024  
select count(a.measurement_concept_id) as total, 
	   sum(case when a.measurement_concept_id = 0 then 1 end) as total_meta, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.measurement_concept_id and b.domain_id = 'Measurement') then 1 end) as ruleCheck 
from measurement a ;
-- R025
select count(a.operator_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.operator_concept_id and b.domain_id = 'Meas Value Operator') then 1 end) as ruleCheck 
from measurement a 
where a.operator_concept_id != 0 ;
-- R026
select count(a.value_as_concept_id) as total, 
       sum(case when exists (select 1 from concept b where b.concept_id = a.value_as_concept_id and b.domain_id = 'Meas Value') then 1 end) as ruleCheck 
from measurement a ;
-- R027 생년월일 년 확인 
select * from cdm.person where year_of_birth::text != to_char(birth_datetime, 'YYYY');
-- R028 생년월일 월 확인 
select * from cdm.person where month_of_birth != to_char(birth_datetime, 'MM')::int;
-- R029 생년월일 일 확인 
select * from cdm.person where day_of_birth != to_char(birth_datetime, 'DD')::int;
-- R030 사망정보 중복 확인 
select person_id, count(1) from cdm.death group by 1 having count(1) > 1 ;
-- R031 내원일자 유효성 확인 
select count(1) from cdm.visit_occurrence where visit_start_date > visit_end_date ;
-- R032 생년월일 점검 
select count(1) from cdm.person where birth_datetime != birth_datetime::date;
-- R033 진단검사 범위값 검증  
select count(1) from cdm.measurement where range_low > range_high;
-- ---------------------------------------------