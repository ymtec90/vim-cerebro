import os
import sys
from flask import Flask, request, jsonify
from llama_index.core import SimpleDirectoryReader, Settings, VectorStoreIndex
from llama_index.embeddings.ollama import OllamaEmbedding
from llama_index.llms.ollama import Ollama

app = Flask(__name__)

# Configurações Globais Iniciais
Settings.embed_model = OllamaEmbedding(model_name="nomic-embed-text")
Settings.chunk_size = 256 
Settings.chunk_overlap = 25 
Settings.llm = Ollama(
    model="qwen2.5:1.5b", 
    request_timeout=600.0, 
    temperature=0.0,
    additional_kwargs={"num_ctx": 2048} 
)

# Variáveis globais
motor_de_busca = None
indice = None # Agora o índice também é global para reaproveitarmos

def inicializar_cerebro():
    global motor_de_busca, indice

    # Define 'dados' como padrão, mas verifica se o Vim enviou parametro --wiki-dir
    diretorio_wiki = "dados"
    if len(sys.argv) > 2 and sys.argv[1] == "--wiki-dir":
        diretorio_wiki = sys.argv[2]

    print(f"🧠 Ligando o servidor e lendo arquivos da wiki em: {diretorio_wiki}")

    # Trava de segurança: Se a pasta não existir, cria a pasta e um arquivo inicial
    # para evitar que o LlamaIndex quebre ao tentar ler uma pasta vazia.
    if not os.path.exists(diretorio_wiki):
        os.makedirs(diretorio_wiki, exist_ok=True)
        with open(os.path.join(diretorio_wiki, "guia.md"), "w") as f:
            f.write("# Segundo Cérebro\nColoque suas anotações Markdown aqui.")

    leitor = SimpleDirectoryReader(input_dir=diretorio_wiki, required_exts=[".md"], recursive=True)
    documentos = leitor.load_data()
    
    indice = VectorStoreIndex.from_documents(documentos)
    motor_de_busca = indice.as_query_engine(similarity_top_k=1)
    print("✅ Segundo Cérebro pronto e escutando na porta 5000!")

@app.route('/perguntar', methods=['POST'])
def perguntar():
    dados = request.get_json()
    if not dados or 'pergunta' not in dados:
        return jsonify({"erro": "Pergunta ausente."}), 400
    
    pergunta_usuario = dados['pergunta']
    contexto_arquivo = dados.get('contexto', '')

    if contexto_arquivo:
        prompt_final = (
            f"Contexto do arquivo atual que estou editando:\n"
            f"--- INICIO DO ARQUIVO ---\n{contexto_arquivo}\n--- FIM DO ARQUIVO ---\n\n"
            f"Pergunta: {pergunta_usuario}"
        )
    else:
        prompt_final = pergunta_usuario

    try:
        resposta = motor_de_busca.query(prompt_final)
        return jsonify({"resposta": str(resposta)})
    except Exception as e:
        return jsonify({"erro": str(e)}), 500

# --- NOVA ROTA: TROCAR MODELO DINAMICAMENTE ---
@app.route('/trocar_modelo', methods=['POST'])
def trocar_modelo():
    global motor_de_busca, indice
    dados = request.get_json()
    
    if not dados or 'modelo' not in dados:
        return jsonify({"erro": "Nome do modelo ausente."}), 400
        
    novo_modelo = dados['modelo']
    print(f"\n[API] Trocando modelo para: {novo_modelo}")
    
    try:
        # 1. Substitui o LLM nas configurações globais
        Settings.llm = Ollama(
            model=novo_modelo, 
            request_timeout=600.0, 
            temperature=0.0,
            additional_kwargs={"num_ctx": 2048} 
        )
        
        # 2. Recria o motor de busca apontando para o novo LLM (sem reler os arquivos)
        motor_de_busca = indice.as_query_engine(similarity_top_k=1)
        
        return jsonify({"sucesso": f"Modelo alterado com sucesso para {novo_modelo}!"})
    except Exception as e:
        print(f"[API] Erro ao trocar modelo: {e}")
        return jsonify({"erro": str(e)}), 500

if __name__ == "__main__":
    inicializar_cerebro()
    app.run(host='127.0.0.1', port=5000)
