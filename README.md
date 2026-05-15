# Team 4 – MoMo Data Project
Momo SMS data processing in XML format

## Project Description
A fullstack application that processes MTN MoMo SMS data in XML format,
cleans and categorizes the transactions, stores them in a SQLite database,
and displays them on a frontend dashboard.

## Team Members
- Moreen Muthoni Murugi
- Emna Barezi

## Project Structure
- `data/` — raw XML data and processed outputs
- `etl/` — Python scripts for parsing, cleaning and loading data
- `web/` — frontend dashboard files
- `api/` — optional FastAPI backend
- `scripts/` — shell scripts to run the ETL pipeline
- `tests/` — unit tests
- `docs/` — documentation and diagrams
- `examples/` — JSON schema examples
- `database/` — SQL database setup scripts

## Architecture Diagram
![Architecture Diagram](architecture_diagram.png)

## Database Design
The database has 4 main tables:
- Transactions — stores all MoMo transaction records
- Users — stores sender and receiver information
- Transaction_Categories — stores transaction types
- System_Logs — tracks data processing events

## Scrum Board
[View our Scrum Board here](https://github.com/users/EmnaBarezi/projects/1/views/1)

## AI Usage
See `docs/ai_usage_log.md` for details on AI tool usage.
