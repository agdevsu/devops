from flask import Flask, request, jsonify
import json

app = Flask(__name__)

@app.route('/devops', methods=['POST'])
def post():
    if request.is_json:  
        content = request.get_json()
        answer = {}
        if "to" in content:    
            answer["message"] = "Hello %s your message will be send" % (content['to'])
            response = json.dumps(answer)
            return response, 200
        return "Bad JSON", 400
    return "Request was not JSON", 400

@app.route('/devops', methods=['GET', 'PUT', 'PATCH', 'DELETE', 'TRACE'])
def others():
    return "ERROR", 400

if __name__ == '__main__':
    app.run(host='0.0.0.0')