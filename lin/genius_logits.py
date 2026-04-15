import numpy as np

def softmax(x):
    # Вычитаем max для численной стабильности
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum(axis=0)

logits = [-3.285, 2.547, 0.9814, 7.199, -4.301, -1.133, -1.946, -0.1633, 0.8921, -3.484]
probabilities = softmax(logits)
print(probabilities) 
val, idx = max((val, idx) for idx, val in enumerate(probabilities))
print(f"I guess: {idx}, with probability: {(100*val):.2f}%") 