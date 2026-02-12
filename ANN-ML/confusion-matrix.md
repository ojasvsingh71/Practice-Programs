# Confusion Matrix

### True Positive (TP) :-

- The Model correctly predicted a positive outcome i.e, the actual outcome was positive.

### True Negative (TN) :-

- The model correctly predicted a negative outcome i.e, the actual outcome was negative.

### False Positive (FP) :-

- The model incorrectly predicted a postive outcome i.e, the actual outcome was negative. It is known as a Type I error.

### False Negative (FN) :-

- The model incorrcetly predicted a negative outcome i.e, the actual outcome was positive. It is known as a Type II error.

---

# 1. Accuracy :-

```python
from sklearn.metrics import accuracy_score

accuracy = accuracy_score(y_true,y_pred)
print("Accuracy :",accuracy)
```

**Formula:**

$$
	ext{Accuracy} = \frac{TP+TN}{TP+TN+FP+FN}
$$

# 2. Precision :-

```python
precision = precision_score(y_true,y_pred)
print("Precision :",precision)
```

**Formula:**

$$
	ext{Precision} = \frac{TP}{TP + FP}
$$

**Interpretation:**
Out of all predicted positives, how many are actually positive.

# 3. Recall (Sensitivity) :-

```python
from sklearn.metrics import recall_score

recall = recall_score(y_true, y_pred)
print("Recall :", recall)
```

**Formula:**

$$
	ext{Recall} = \frac{TP}{TP + FN}
$$

**Interpretation:**
Out of all actual positives, how many were correctly predicted.

# 4. F1 Score :-

```python
from sklearn.metrics import f1_score

f1 = f1_score(y_true, y_pred)
print("F1 Score :", f1)
```

**Formula:**

$$
	ext{F1 Score} = 2 \times \frac{\text{Precision} \times \text{Recall}}{\text{Precision} + \text{Recall}}
$$

**Interpretation:**
Harmonic mean of Precision and Recall. Useful for imbalanced datasets.

# 5. Specificity :-

**Formula:**

$$
	ext{Specificity} = \frac{TN}{TN + FP}
$$

**Interpretation:**
Out of all actual negatives, how many were correctly predicted.

# Confusion Matrix Table

|                 | Predicted Positive | Predicted Negative |
| --------------- | ------------------ | ------------------ |
| Actual Positive | TP                 | FN                 |
| Actual Negative | FP                 | TN                 |

Visual Representation:

$$
\begin{bmatrix}
TP & FP \\
FN & TN
\end{bmatrix}
$$

# Example Confusion Matrix

Suppose:

|                 | Predicted Positive | Predicted Negative |
| --------------- | ------------------ | ------------------ |
| Actual Positive | 50                 | 10                 |
| Actual Negative | 5                  | 35                 |

TP = 50, FP = 5, FN = 10, TN = 35

**Accuracy:** $\frac{50+35}{50+35+5+10} = 0.85$

**Precision:** $\frac{50}{50+5} = 0.909$

**Recall:** $\frac{50}{50+10} = 0.833$

**F1 Score:** $2 \times \frac{0.909 \times 0.833}{0.909+0.833} = 0.87$

**Specificity:** $\frac{35}{35+5} = 0.875$

# 6. Additional Metrics

- **Type I Error (False Positive Rate):** $\frac{FP}{FP+TN}$
- **Type II Error (False Negative Rate):** $\frac{FN}{FN+TP}$

# 7. When to Use Which Metric?

- **Accuracy:** Good for balanced datasets.
- **Precision:** Important when false positives are costly (e.g., spam detection).
- **Recall:** Important when false negatives are costly (e.g., disease detection).
- **F1 Score:** Useful for imbalanced classes.
- **Specificity:** Useful in medical tests to measure true negative rate.

# Type 1 error and Type 2 error

## Type I Error (False Positive)

- Predicting positive when actual is negative.
- Example: Diagnosing a healthy person as sick.
- Formula: $\text{Type I Error Rate} = \frac{FP}{FP+TN}$

## Type II Error (False Negative)

- Predicting negative when actual is positive.
- Example: Diagnosing a sick person as healthy.
- Formula: $\text{Type II Error Rate} = \frac{FN}{FN+TP}$

# Summary Table

| Metric        | Formula                                                     | Interpretation                       |
| ------------- | ----------------------------------------------------------- | ------------------------------------ |
| Accuracy      | $\frac{TP+TN}{TP+TN+FP+FN}$                                 | Overall correct predictions          |
| Precision     | $\frac{TP}{TP+FP}$                                          | Correct positive predictions         |
| Recall        | $\frac{TP}{TP+FN}$                                          | Correctly identified positives       |
| F1 Score      | $2 \times \frac{Precision \times Recall}{Precision+Recall}$ | Balance between precision and recall |
| Specificity   | $\frac{TN}{TN+FP}$                                          | Correctly identified negatives       |
| Type I Error  | $\frac{FP}{FP+TN}$                                          | False positive rate                  |
| Type II Error | $\frac{FN}{FN+TP}$                                          | False negative rate                  |

# Practical Tips

- Use **accuracy** for balanced datasets.
- Use **precision** when false positives are costly.
- Use **recall** when false negatives are costly.
- Use **F1 score** for imbalanced datasets.
- Use **specificity** for medical tests.
