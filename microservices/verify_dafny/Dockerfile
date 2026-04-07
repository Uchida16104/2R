FROM python:3.12-slim
WORKDIR /app

RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 3002
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "3002"]
