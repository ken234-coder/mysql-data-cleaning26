# Customer Survey Data Cleaning (MySQL)

## Overview
Cleaned a messy customer survey dataset using MySQL.

## Dataset
- `raw_data.csv`: original messy data
- `cleaned_data.csv`: final cleaned output
- Columns: customer_id, survey_date, survey_time, rewards_member,
  service_feedback, freetext_response, email, phone, address

## Problems Found
- Duplicate customer records
- Blank emails and phone numbers
- Addresses stored in a single column
- Dates and times stored as text
- Inconsistent service feedback labels
- Extra whitespace and inconsistent casing

## Cleaning Steps
1. Created a working copy of the raw table
2. Removed duplicates with ROW_NUMBER(), keeping each customer's latest record
3. Converted blank emails/phones to NULL and merged them into one `contact` column
4. Split `address` into `street`, `city` and `state`
5. Standardized `rewards_member` with TRIM and UPPER
6. Converted `survey_date` and `survey_time` to DATE and TIME types
7. Standardized `service_feedback` categories with CASE
8. Trimmed whitespace from free-text responses

## Tools
- MySQL Workbench

## Files
- `data_cleaning.sql`: full cleaning script
