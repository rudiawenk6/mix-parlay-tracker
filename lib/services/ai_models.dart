/// Available free models on OpenRouter
class AiModels {
  static const List<Map<String, String>> freeModels = [
    {'id': 'google/gemini-2.0-flash-001', 'name': 'Gemini 2.0 Flash', 'provider': 'Google', 'ctx': '1M'},
    {'id': 'meta-llama/llama-4-maverick:free', 'name': 'Llama 4 Maverick', 'provider': 'Meta', 'ctx': '128K'},
    {'id': 'meta-llama/llama-4-scout:free', 'name': 'Llama 4 Scout', 'provider': 'Meta', 'ctx': '128K'},
    {'id': 'meta-llama/llama-3.3-70b-instruct:free', 'name': 'Llama 3.3 70B', 'provider': 'Meta', 'ctx': '128K'},
    {'id': 'mistralai/mistral-small-3.1-24b-instruct:free', 'name': 'Mistral Small 3.1', 'provider': 'Mistral', 'ctx': '128K'},
    {'id': 'qwen/qwen3-32b:free', 'name': 'Qwen 3 32B', 'provider': 'Qwen', 'ctx': '128K'},
    {'id': 'qwen/qwen3-14b:free', 'name': 'Qwen 3 14B', 'provider': 'Qwen', 'ctx': '128K'},
    {'id': 'qwen/qwen3-8b:free', 'name': 'Qwen 3 8B', 'provider': 'Qwen', 'ctx': '32K'},
    {'id': 'deepseek/deepseek-r1-0528:free', 'name': 'DeepSeek R1', 'provider': 'DeepSeek', 'ctx': '64K'},
    {'id': 'deepseek/deepseek-chat-v3-0324:free', 'name': 'DeepSeek V3', 'provider': 'DeepSeek', 'ctx': '64K'},
    {'id': 'microsoft/mai-ds-r1:free', 'name': 'MAI DS R1', 'provider': 'Microsoft', 'ctx': '64K'},
    {'id': 'nvidia/llama-3.1-nemotron-70b-instruct:free', 'name': 'Nemotron 70B', 'provider': 'NVIDIA', 'ctx': '128K'},
  ];

  static String defaultModel = freeModels[0]['id']!;
  
  static String getModelName(String id) {
    final found = freeModels.where((m) => m['id'] == id);
    if (found.isNotEmpty) return found.first['name']!;
    return id.split('/').last;
  }
  
  static String getProvider(String id) {
    final found = freeModels.where((m) => m['id'] == id);
    if (found.isNotEmpty) return found.first['provider']!;
    return '';
  }
}
