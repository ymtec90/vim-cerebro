import pytest
from api.api import app
from unittest.mock import Mock

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_perguntar_no_context(client, mocker):
    # Mock the query engine
    mock_query = mocker.patch('api.api.motor_de_busca')
    mock_query.query.return_value = "Esta é uma resposta de teste."

    response = client.post('/perguntar', json={
        "pergunta": "Qual é o sentido da vida?"
    })

    assert response.status_code == 200
    assert response.get_json() == {"resposta": "Esta é uma resposta de teste."}

    # Ensure query was called with just the question
    mock_query.query.assert_called_once_with("Qual é o sentido da vida?")

def test_perguntar_with_context(client, mocker):
    # Mock the query engine
    mock_query = mocker.patch('api.api.motor_de_busca')
    mock_query.query.return_value = "A resposta baseada no contexto."

    contexto = "42"
    pergunta = "Qual é o sentido da vida?"

    response = client.post('/perguntar', json={
        "pergunta": pergunta,
        "contexto": contexto
    })

    assert response.status_code == 200
    assert response.get_json() == {"resposta": "A resposta baseada no contexto."}

    # Check the prompt format
    expected_prompt = (
        f"Contexto do arquivo atual que estou editando:\n"
        f"--- INICIO DO ARQUIVO ---\n{contexto}\n--- FIM DO ARQUIVO ---\n\n"
        f"Pergunta: {pergunta}"
    )
    mock_query.query.assert_called_once_with(expected_prompt)

def test_perguntar_missing_pergunta(client):
    response = client.post('/perguntar', json={
        "contexto": "Algum contexto"
    })

    assert response.status_code == 400
    assert response.get_json() == {"erro": "Pergunta ausente."}

def test_perguntar_missing_json(client):
    response = client.post('/perguntar', json={})

    assert response.status_code == 400
    assert response.get_json() == {"erro": "Pergunta ausente."}

def test_perguntar_server_error(client, mocker):
    # Mock the query engine to raise an exception
    mock_query = mocker.patch('api.api.motor_de_busca')
    mock_query.query.side_effect = Exception("Erro interno do LlamaIndex")

    response = client.post('/perguntar', json={
        "pergunta": "Vai dar erro?"
    })

    assert response.status_code == 500
    assert response.get_json() == {"erro": "Erro interno do LlamaIndex"}
