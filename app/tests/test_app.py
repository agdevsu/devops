from app.app import app
import json

def test_post_devops():
    response = app.test_client().post(
        '/devops',
        data=json.dumps({"message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45}),
        content_type='application/json',
    )
    
    data = json.loads(response.get_data(as_text=True))

    assert response.status_code == 200
    assert data["message"] == "Hello Juan Perez your message will be send"

def test_get_devops():
    response = app.test_client().get('/devops')

    assert response.status_code == 400
    expected = "ERROR"
    assert expected == response.get_data(as_text=True)

def test_put_devops():
    response = app.test_client().put('/devops')

    assert response.status_code == 400
    expected = "ERROR"
    assert expected == response.get_data(as_text=True)

def test_patch_devops():
    response = app.test_client().patch('/devops')

    assert response.status_code == 400
    expected = "ERROR"
    assert expected == response.get_data(as_text=True)

def test_delete_devops():
    response = app.test_client().delete('/devops')

    assert response.status_code == 400
    expected = "ERROR"
    assert expected == response.get_data(as_text=True)

def test_trace_devops():
    response = app.test_client().trace('/devops')

    assert response.status_code == 400
    expected = "ERROR"
    assert expected == response.get_data(as_text=True)
