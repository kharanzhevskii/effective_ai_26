import torch
import torch.nn as nn
import torch.optim as optim
import numpy as np

# --- Гиперпараметры ---
V = 4          # Размер словаря (a=0, b=1, c=2, d=3)
T = 4          # Длина последовательности
d = 16         # Размерность эмбеддинга (d_model). 16 идеально для sim8!

# --- Создаем архитектуру Мини-Трансформера ---
class MiniTransformer(nn.Module):
    def __init__(self):
        super().__init__()
        # 1. Эмбеддинги
        self.tok_emb = nn.Embedding(V, d)
        self.pos_emb = nn.Parameter(torch.randn(T, d) * 0.02)
        
        # 2. LayerNorm 1
        self.ln1 = nn.LayerNorm(d)
        
        # 3. Attention (без bias для экономии памяти в sim8)
        self.W_q = nn.Linear(d, d, bias=False)
        self.W_k = nn.Linear(d, d, bias=False)
        self.W_v = nn.Linear(d, d, bias=False)
        self.W_o = nn.Linear(d, d, bias=False)
        
        # 4. LayerNorm 2
        self.ln2 = nn.LayerNorm(d)
        
        # 5. FFN / MLP
        self.fc1 = nn.Linear(d, 4 * d) # расширяем в 4 раза (классика)
        self.fc2 = nn.Linear(4 * d, d)
        
        # 6. Голова предсказания
        self.head = nn.Linear(d, V)

    def forward(self, x):
        # x shape: [Batch, T]
        B = x.shape[0]
        
        # --- Эмбеддинги ---
        h = self.tok_emb(x) + self.pos_emb # [B, T, d]
        
        # --- Блок Трансформера ---
        # Внимание
        h_norm = self.ln1(h)
        Q = self.W_q(h_norm)
        K = self.W_k(h_norm)
        V_mat = self.W_v(h_norm)
        
        scores = torch.matmul(Q, K.transpose(-2, -1)) / (d ** 0.5)
        attn = torch.softmax(scores, dim=-1)
        
        context = torch.matmul(attn, V_mat)
        out_attn = self.W_o(context)
        
        h = h + out_attn # Residual 1
        
        # FFN
        h_norm2 = self.ln2(h)
        ffn_out = self.fc2(torch.relu(self.fc1(h_norm2)))
        
        h = h + ffn_out # Residual 2
        
        # --- Голова ---
        logits = self.head(h) # [B, T, V]
        return logits

# --- Инициализация и Обучение ---
model = MiniTransformer()
optimizer = optim.Adam(model.parameters(), lr=0.01)
criterion = nn.CrossEntropyLoss()

print("Начинаем обучение...")
for epoch in range(300):
    # Генерируем случайные последовательности из 4 символов
    x = torch.randint(0, V, (128, T))
    y = x.clone() # Цель - повторить вход! (Identity task)
    
    optimizer.zero_grad()
    logits = model(x) # [128, 4, 4]
    
    # Считаем loss (нужно сплющить батч и токены)
    loss = criterion(logits.view(-1, V), y.view(-1))
    loss.backward()
    optimizer.step()
    
    if epoch % 50 == 0:
        print(f"Epoch {epoch} | Loss: {loss.item():.4f}")

# Проверка
test_seq = torch.tensor([[1, 1, 3, 3]]) # b, b, d, d
pred = model(test_seq).argmax(dim=-1)
print(f"Вход:  {test_seq.tolist()[0]}")
print(f"Выход: {pred.tolist()[0]}")

# --- Экспорт весов в бинарник для sim8 ---
# sim8 VDOT ожидает веса построчно в формате [out_features, in_features], 
# что идеально совпадает с внутренним форматом nn.Linear.weight в PyTorch!

def export_tensor(tensor, f):
    # Переводим в float16 и пишем как raw bytes
    np_arr = tensor.detach().numpy().astype(np.float16)
    f.write(np_arr.tobytes())

with open("transformer_weights.bin", "wb") as f:
    export_tensor(model.tok_emb.weight, f)
    export_tensor(model.pos_emb, f)
    
    # LayerNorm 1 (gamma и beta)
    export_tensor(model.ln1.weight, f)
    export_tensor(model.ln1.bias, f)
    
    # Attention
    export_tensor(model.W_q.weight, f)
    export_tensor(model.W_k.weight, f)
    export_tensor(model.W_v.weight, f)
    export_tensor(model.W_o.weight, f)
    
    # LayerNorm 2
    export_tensor(model.ln2.weight, f)
    export_tensor(model.ln2.bias, f)
    
    # FFN
    export_tensor(model.fc1.weight, f)
    export_tensor(model.fc1.bias, f)
    export_tensor(model.fc2.weight, f)
    export_tensor(model.fc2.bias, f)
    
    # Head
    export_tensor(model.head.weight, f)
    export_tensor(model.head.bias, f)

print("\nВеса успешно сохранены в 'transformer_weights.bin'")