# OHDSI-DQC 

## OHDSI CDM 검증SQL 생성 및 검증  

## DQC Description   
1. description: OHDSI CDM 기본 스키마 및 데이터 점검 SQL입니다. Primary key, Foreign Key 설정등 CDM Doc에서 정의한 
                기준으로 설정되어 있음을 전제로 하여 점검하게 됩니다. CDM 표준을 따르지 않으면 점검이 정상적으로 되지 않습니다. 
2. create date: 2022.05 
3. edited date: 2022.06 
4. DB 정의서 
5. Table 정의서 
6. 컬럼 정의서
7. Domain 정의서 
8. 업무규칙 모집단 기준, 기간 등등 코드 기준. 

## 정의룰 항목 
1. Schema검증 15개, 개념검증 33개 

## 검증룰 적용 기본요건 
1. OHDSI DDL 정의기준을 준수 
2. 기본키, 참조키 정의 준수 

## SQL 사용환경 
1. PostgreSQL 환경 
2. 테스트 환경 
   PostgreSQL 13.3 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.3.1 20191121 (Red Hat 8.3.1-5), 64-bit

## SQL 사용방법 
1. 스키마를 설정 
``` 
@set schema_name = {schema name of cdm};      
```
2. 설정된 스키마 확인 
``` 
select '${schema_name}'; 
```

### copywrite@ fingertree@gmail.com  

