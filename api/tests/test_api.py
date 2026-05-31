import pytest
from unittest.mock import patch, MagicMock

# Adjust the path to import the app from api.api
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from api import app
import api

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_trocar_modelo_missing_model(client):
    """Test that a 400 is returned when the model name is missing."""
    response = client.post('/trocar_modelo', json={})
    assert response.status_code == 400
    assert response.get_json() == {"erro": "Nome do modelo ausente."}

@patch('api.Settings')
@patch('api.Ollama')
def test_trocar_modelo_success(mock_ollama, mock_settings, client):
    """Test that providing a valid model updates settings and returns 200."""
    # Mock api.indice
    mock_indice = MagicMock()
    mock_motor_de_busca = MagicMock()
    mock_indice.as_query_engine.return_value = mock_motor_de_busca
    api.indice = mock_indice

    response = client.post('/trocar_modelo', json={'modelo': 'novo-modelo:latest'})

    # Assert successful response
    assert response.status_code == 200
    assert response.get_json() == {"sucesso": "Modelo alterado com sucesso para novo-modelo:latest!"}

    # Assert Ollama was called correctly
    mock_ollama.assert_called_once_with(
        model='novo-modelo:latest',
        request_timeout=600.0,
        temperature=0.0,
        additional_kwargs={"num_ctx": 2048}
    )

    # Assert query engine was updated
    mock_indice.as_query_engine.assert_called_once_with(similarity_top_k=1)
    assert api.motor_de_busca == mock_motor_de_busca

@patch('api.Settings')
@patch('api.Ollama')
def test_trocar_modelo_exception(mock_ollama, mock_settings, client):
    """Test that a 500 is returned when an exception occurs during model update."""
    mock_ollama.side_effect = Exception("Test Error")

    response = client.post('/trocar_modelo', json={'modelo': 'novo-modelo:latest'})

    assert response.status_code == 500
    assert response.get_json() == {"erro": "Test Error"}
