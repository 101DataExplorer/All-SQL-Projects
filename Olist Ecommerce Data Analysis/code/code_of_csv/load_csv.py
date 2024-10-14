import pandas as pd
from sqlalchemy import create_engine

conn_string = 'postgresql://postgres:$$psgsql%%@localhost/portfolio_projects'
db = create_engine(conn_string)
conn = db.connect()


# print(df.info)

files = ['customers','geolocation', 'order_items', 'order_payments', 'order_reviews', 'orders',
         'products', 'sellers', 'product_category_name_translation']


for file in files:
    df = pd.read_csv(f'E:/SQL/Portfolio_Projects/E-commerce Analysis Brazilian E-commerce Dataset/data set/csv_files/{file}.csv')
    df.to_sql(file, con = conn, schema='olist_ecommerce', if_exists='replace', index= False )