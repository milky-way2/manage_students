"""This is a simple student database management system."""
import os
from typing import Union, Optional
import mysql.connector
from dotenv import load_dotenv
from tabulate import tabulate


def main() -> None:
    """It is the starting function called main."""
    while True:
        try:
            connection: mysql.connector.connection_cext.CMySQLConnection
            cursor: mysql.connector.cursor_cext.CMySQLCursor
            connection, cursor = database()
            choice: int = int(input(
"""Enter 1 to insert new Records of students.
Enter 2 to Remove any records by student Roll No.
Enter 3 to Show records of existing students.
Enter 4 for add new Student's Attribute.
Enter 5 for remove  Student's Attribute.
Enter 6 for update value of any student's attribute.
Enter 7 to exit. : """))
            if choice == 7:
                close_db(cursor, connection)
                print("Bye...")
                break
            if choice == 1:
                insert_student(cursor, connection)
            elif choice == 2:
                delete_student(cursor, connection)
            elif choice == 3:
                print(show_students(cursor))
            elif choice == 4:
                add_column(cursor, connection)
            elif choice == 5:
                remove_column(cursor, connection)
            elif choice == 6:
                update_column(cursor, connection)
            else:
                print("Try again.....")
        except Exception as error_name:
            print(f"Error {error_name} occured.....")


def database() -> tuple[mysql.connector.connection_cext.CMySQLConnection, mysql.connector.cursor_cext.CMySQLCursor]:
    """
    Connecting with Db and returning the cursor and connection  for manipulation
    Union[str,None] and Optional[str] are equivalent from typing
    """
    load_dotenv()
    mysql_host: Union[str,None] = os.getenv("MYSQL_HOST")
    mysql_user: Union[str,None] = os.getenv("MYSQL_USER")
    mysql_password: Optional[str] = os.getenv("MYSQL_PASSWORD")
    connection: mysql.connector.connection_cext.CMySQLConnection = mysql.connector.connect(host = mysql_host, user = mysql_user, password = mysql_password, database="students")
    cursor: mysql.connector.cursor_cext.CMySQLCursor = connection.cursor()
    return connection, cursor


def close_db(cursor: mysql.connector.cursor_cext.CMySQLCursor, connection: mysql.connector.connection_cext.CMySQLConnection) -> None:
    """This function is use to close the connection with database after work."""
    cursor.close()
    connection.close()


def insert_student(cursor: mysql.connector.cursor_cext.CMySQLCursor, connection: mysql.connector.connection_cext.CMySQLConnection) -> None:
    """This function is inserting newstudent details."""
    #Fetching Attributes name for insert values
    cursor.execute("select Attribute_Name from Attributes_Details;")
    attributes_name: list[str] = [row[0] for row in cursor.fetchall()]
    attributes_values : list[str] = []
    #Genrating place holder for query
    params: str = "(" + ", ".join(["%s" for _ in range(len(attributes_name))]) + ")"
    for attribute in attributes_name:
        value:str = input(f"Enter {attribute} of the student: ")
        attributes_values.append(value)
    column_order: str = "(" + ", ".join(attributes_name) + ")"
    query: str = f"insert into student {column_order} values {params};"
    # params_values: tuple[str] = tuple(attributes_values) #This also works
    params_values: list[str] = attributes_values
    cursor.execute(query, params_values)
    cursor.fetchall()
    connection.commit()
    print("Student details saved.....")


def delete_student(cursor: mysql.connector.cursor_cext.CMySQLCursor, connection: mysql.connector.connection_cext.CMySQLConnection) -> None:
    """This function is to remove an already existing student from Database."""
    roll_no: str = input("Enter Student Roll No to remove this student: ")
    query: str = "delete from student where RollNo=%s;"
    params: tuple[str] = (roll_no,)
    cursor.execute(query, params)
    cursor.fetchall()
    connection.commit()
    print("Student details removed.....")


def show_students(cursor: mysql.connector.cursor_cext.CMySQLCursor) -> str:
    """This function is to show all presnt students details from the database."""
    query: str = "select * from student;"
    cursor.execute(query)
    students = cursor.fetchall()
    attributes = [column[0] for column in cursor.description]
    student_table: str = tabulate(students, headers=attributes, tablefmt="grid")
    return student_table


def add_column(cursor: mysql.connector.cursor_cext.CMySQLCursor, connection: mysql.connector.connection_cext.CMySQLConnection) -> None:
    """This column add new attribute at each call to a existing DB."""
    column: str = input("Enter New column or attribute name : ")
    data_type: str = input("Enter column data type : ")
    size: str = "0"
    nullable: str = input("Do you want to make this attribute NULL able or Not. For yes Enter y & for no enter n : ")
    if data_type.lower() == "varchar":
        size = input("Enter Size of varchar data type : ")
        query: str = f"alter table student add column {column} {data_type}({size})"
    else:
        query = f"alter table student add column {column} {data_type}"
    if nullable.lower() == "n":
        query += " not NULL"
    query += ";"
    cursor.execute(query)
    cursor.fetchall()
    connection.commit()
    print("New attribute added.....\nNow insert new values for newly added Attribute.....")
    update_attribute_deatils: str = "insert into Attributes_Details values (%s, %s);"
    params: tuple[str,str] = (column, data_type)
    cursor.execute(update_attribute_deatils, params)
    cursor.fetchall()
    connection.commit()


def remove_column(cursor: mysql.connector.cursor_cext.CMySQLCursor, connection: mysql.connector.connection_cext.CMySQLConnection) -> None :
    """This column remove a attribute at each call from a existing DB by simply attribute name."""
    column: str = input("Enter attribute name want to remove : ")
    query: str = f"alter table student drop column {column};"
    cursor.execute(query)
    cursor.fetchall()
    connection.commit()
    print("Attribute removed.....")
    update_attribute_deatils: str = "delete from Attributes_Details where Attribute_Name = %s"
    params: tuple[str] = (column, )
    cursor.execute(update_attribute_deatils, params)
    cursor.fetchall()
    connection.commit()



def update_column(cursor: mysql.connector.cursor_cext.CMySQLCursor, connection: mysql.connector.connection_cext.CMySQLConnection) -> None :
    """It update value of a attribute at each call by matching student Roll No."""
    column: str = input("Enter Attribute name want to update : ")
    #fetching attribute's Data type
    cursor.execute(f"select Data_Type from Attributes_Details where Attribute_Name = '{column}';")
    data_type: tuple[str] = cursor.fetchone()
    if data_type is not None:
        data_type = data_type[0]
        new_value: str = input("Enter new value : ")
        roll_no: str = input("Enter student Roll No want to update : ")
        if data_type.lower() == "varchar":
            query: str = f"update student set {column} = '{new_value}' where RollNo = {roll_no};"
        else:
            query = f"update student set {column} = {new_value} where RollNo = {roll_no};"
        cursor.execute(query)
        cursor.fetchall()
        connection.commit()
        print("Student details updated.....")


if __name__ == "__main__":
    main()
