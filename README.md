# E-Commerce-Data-Engineering-Pipeline-using-Snowflake

<img width="1536" height="1024" alt="ChatGPT Image May 18, 2026, 11_35_02 PM" src="https://github.com/user-attachments/assets/8082263d-f253-4cbd-acf7-feef2f1e9a61" />



## 📌 Project Overview

This project is a complete End-to-End Data Engineering Pipeline built on Snowflake using Medallion Architecture (Bronze, Silver, Gold).

The project simulates a real-world e-commerce system where customer, product, sales, store, and order data are loaded into Snowflake and processed using incremental pipelines.

The main goal of this project is to understand how enterprise ETL/ELT pipelines work using Snowflake features like:

- Stages
- COPY INTO
- Streams
- Tasks
- MERGE
- SCD Type 2
- CDC (Change Data Capture)
- Gold Layer Analytics

---

# 🏗️ Architecture Used

```text
RAW FILES
   ↓
STAGE
   ↓
BRONZE LAYER
   ↓
STREAMS
   ↓
STAGING TABLES
   ↓
SILVER LAYER
   ↓
GOLD LAYER
```

---

## 📌 Author

**Divyansh Patel**
Data Engineer | SQL | Databricks | Analytics

🔗 LinkedIn: https://www.linkedin.com/in/divyansh-patel-dataanalyst/
- divyanshpatel751@gmail.com

---

⭐ If you find this project useful, feel free to star the repository!

