import json
import logging
import os

import azure.functions as func
import requests

app = func.FunctionApp()

# sample function
@app.route(route="HttpTrigger", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
def http_trigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Http request triggered")

    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

    if name:
        return func.HttpResponse(f"Hello, {name}. This HTTP triggered function executed successfully.")
    else:
        return func.HttpResponse(
             body="This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
             status_code=200
        )


@app.route(route="GenerateEmbeddings", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
def generate_embeddings(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Generating embeddings triggered")

    AI_SERVICE_ENDPOINT = os.environ['AI_SERVICE_ENDPOINT']
    AI_SERVICE_API_KEY = os.environ['AI_SERVICE_API_KEY']

    res_msg = {
        "message": "",
        "vector": [],
        "code": ""
    }

    # check header
    if "Content-Type" not in req.headers:
        msg = "Missing Content-Type header."
        logging.error(msg)
        res_msg["message"] = msg
        res_msg["code"] = 400

        return func.HttpResponse(
            body=json.dumps(res_msg),
            status_code=res_msg["code"]
        )
    else:
        content_type = req.headers["Content-Type"]
        if content_type != "application/octet-stream":
            msg = "Invalid content type. Expected application/octet-stream."
            logging.error(msg)
            res_msg["message"] = msg
            res_msg["code"] = 400

            return func.HttpResponse(
                body=json.dumps(res_msg),
                status_code=res_msg["code"]
            )
    
    # check body
    image = req.get_body()
    if not image:
        logging.error("No image data in the request body.")
        res_msg["message"] = "No image data in the request body."
        res_msg["code"] = 400

        return func.HttpResponse(
            body=json.dumps(res_msg),
            status_code=res_msg["code"]
        )

    # generate embeddings
    url = f"{AI_SERVICE_ENDPOINT}/computervision/retrieval:vectorizeImage"
    params = {
        "api-version": "2023-02-01-preview",
        "modelVersion": "latest"
    }
    headers = {
        "Content-Type": "application/octet-stream",
        "Ocp-Apim-Subscription-Key": AI_SERVICE_API_KEY
    }

    logging.info("Request to AI services")
    response = requests.post(url, params=params, headers=headers, data=image)
    logging.info(f"status_code: {response.status_code}")
  
    if response.status_code == 200:
        msg = "Embeddings generated successfully"
        logging.info(msg)

        res_msg["message"] = msg
        res_msg["vector"] = response.json()["vector"]
        res_msg["code"] = 200

    else:
        msg = f'Generate embeddings failed'
        logging.error(msg)
        logging.error(response.text)

        res_msg["message"] = msg
        res_msg["code"] = 500
    
    return func.HttpResponse(
        body=json.dumps(res_msg),
        status_code=res_msg["code"]
    )

