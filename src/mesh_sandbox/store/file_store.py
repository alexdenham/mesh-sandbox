import os.path
from typing import Optional

from ..common import EnvConfig
from ..models.message import Message
from .memory_store import MemoryStore


class FileStore(MemoryStore):
    def __init__(self, config: EnvConfig):
        super().__init__(config)
        self._base_dir = config.file_store_dir

    def chunk_path(self, message: Message, chunk_number: int) -> str:
        return os.path.join(self._base_dir, f"{message.recipient.mailbox_id}/in/{message.message_id}/{chunk_number}")

    async def receive_chunk(self, message: Message, chunk_number: int, chunk: bytes):
        chunk_path = self.chunk_path(message, chunk_number)
        os.makedirs(os.path.dirname(chunk_path), exist_ok=True)
        with open(chunk_path, "wb+") as f:
            f.write(chunk)

    async def retrieve_chunk(self, message: Message, chunk_number: int) -> Optional[bytes]:

        chunk_path = self.chunk_path(message, chunk_number)
        if not os.path.exists(chunk_path):
            return None

        with open(chunk_path, "rb+") as f:
            return f.read()
