import os
from langchain_community.utilities import SQLDatabase
from langchain_community.agent_toolkits import create_sql_agent
from langchain_google_genai import ChatGoogleGenerativeAI

# 1. SETUP CONFIGURATION
# Replace with your actual values
DB_USER = "your_username"
DB_PASSWORD = "your_password"
DB_HOST = "localhost"
DB_NAME = "telco_churn"
GOOGLE_API_KEY = "your_google_gemini_api_key"

# Set API key for the environment
os.environ["GOOGLE_API_KEY"] = GOOGLE_API_KEY

def main():
    try:
        # 2. CONNECT TO MYSQL DATABASE
        # We use SQLAlchemy format: mysql+mysqlconnector://user:pass@host/db_name
        db_uri = f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
        db = SQLDatabase.from_uri(db_uri)
        
        print("Successfully connected to the database.")

        # 3. INITIALIZE GEMINI LLM
        # using 'gemini-1.5-flash' for speed/cost, or 'gemini-1.5-pro' for reasoning
        llm = ChatGoogleGenerativeAI(
            model="gemini-2.0-flash",
            temperature=0  # 0 is best for code/SQL generation to reduce hallucinations
        )

        # 4. CREATE THE SQL AGENT
        # The agent_type="openai-tools" or "tool-calling" is standard, 
        # but LangChain handles the default agent setup automatically here.
        agent_executor = create_sql_agent(
            llm=llm,
            db=db,
            verbose=True, # Set to True to see the agent's thought process in the console
            agent_type="tool-calling"
        )

        # 5. RUN THE AGENT
        user_question = "List the table names in this database and count the total rows in the most populated table."
        
        print(f"\nUser Question: {user_question}\n")
        response = agent_executor.invoke(user_question)
        
        print(f"\nFinal Answer: {response['output']}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
