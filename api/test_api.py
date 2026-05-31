import pytest
from api import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_perguntar_error_handling(client, mocker):
    # Setup mock for motor_de_busca
    mock_motor = mocker.Mock()
    mock_motor.query.side_effect = Exception("Test error from query")
    mocker.patch('api.motor_de_busca', mock_motor)

    # Make the request
    response = client.post('/perguntar', json={'pergunta': 'Qual o sentido da vida?'})

    # Assert
    assert response.status_code == 500
    assert response.get_json() == {"erro": "Test error from query"}
