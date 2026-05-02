# Database Project / KSeF

This repository contains a SQL script for building a database that supports invoice processing in the KSeF format. It includes the target tables, staging tables, error logging, and stored procedures for moving data and generating invoice XML.

## What the project does

- creates the `Ksef` database in SQL Server,
- sets up country and currency dictionaries,
- defines tables for the seller, buyer, invoice, and invoice lines,
- stores temporary data in staging tables,
- records execution history and errors in `LOG_H` and `LOG_ERR`,
- transfers data from staging into the final tables,
- generates KSeF-compliant XML for a selected invoice.

## Repository structure

- `baza_sql.sql` - main DDL/DML script, procedures, and sample data,
- `input/` - input files used for testing,
- `schematy/` - XSD schema files,
- `KSEF/` - ETL / SSIS project and SQL solution files,
- `zrobiony_xml/` - generated example XML files,
- `bazy_sem6 (1).pdf` - the written report for the project, available in Polish.

## Requirements

- Microsoft SQL Server,
- SQL Server Management Studio or another tool capable of running T-SQL scripts,
- permissions to create databases and stored procedures.

## How to run

1. Open `baza_sql.sql` in SSMS.
2. Execute the full script on the SQL Server instance.
3. The script creates the `Ksef` database, tables, procedures, and sample data.
4. You can also open the `KSEF` project in Visual Studio with SSIS support and run the ETL flow there.

The SSIS package executes the stored procedures and loads data from the input files into the database.

After running the script, you can inspect these tables:

- `Podmiot1`
- `Podmiot2`
- `Fa`
- `FaWiersz`
- `LOG_H`
- `LOG_ERR`

## Main procedures

### `pr_PrzeniesDaneZETL`

This procedure validates data in the staging tables and then moves it into the final tables. It checks, among other things:

- the number of records in the header,
- seller and buyer data consistency,
- country and currency codes,
- invoice date format,
- invoice number uniqueness,
- whether amounts and quantities can be cast to numeric types.

If an error occurs, the procedure clears the staging tables and writes the issue to the log.

### `GenerujKSeF_XML`

This procedure generates XML for the invoice identified by its number:

```sql
EXEC GenerujKSeF_XML @NumerFaktury = 'F/001/2026';
```

The XML contains the header data, party data, invoice section, and invoice line items.

## Example workflow

1. Load data into `Staging_Naglowek` and `Staging_Pozycje`.
2. Run `pr_PrzeniesDaneZETL` or start the ETL package from the `KSEF` folder in Visual Studio.
3. Check whether records were inserted into `Podmiot1`, `Podmiot2`, `Fa`, and `FaWiersz`.
4. Run `GenerujKSeF_XML` to generate XML for a single invoice.

## Notes

- The script assumes test data in a few places, so it is best to run it on an empty database.
- The invoice number in `Fa` is unique, so duplicate data will be rejected.
- The validations in the procedure are intentionally strict and may stop the import when a record is invalid.
