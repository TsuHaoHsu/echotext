from motor.motor_asyncio import AsyncIOMotorClient
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    mongo_uri: str = "mongodb://192.168.0.195:27017"

settings = Settings()

client = AsyncIOMotorClient(settings.mongo_uri)
database = client["Echo_Text_Local"]
