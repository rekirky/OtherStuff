import json
import fitz  # PyMuPDF
import os
from tkinter.filedialog import askopenfilename

# Path to the input file
input_file = askopenfilename()   # Replace with your inport file

# Load the JSON file
with open(input_file, "r", encoding="utf-8") as f:
    data = json.loads(f.read())

# Extract recipe and ingredient list
recipe = data[0][0]  # First item in dataset

# Ensure nip is parsed correctly (Fix for TypeError)
nip_data = json.loads(recipe["nip"])  # Convert string to dictionary

# Extract servings info
servings_per_package = float(nip_data["SERVESPERPACKAGE"])
serving_size = float(nip_data["SERVESIZE"])

# Compute total weight
total_weight = serving_size * servings_per_package  # 201g in example
ingredients = json.loads(recipe["ingredients"])  # Convert ingredients to list

# Nutrients to extract
nutrients = ["ENERGY", "PROTEIN", "FAT", "SATURATED", "CARBOHYDRATE", "SUGARS", "SODIUM"]
totals = {nutrient: 0 for nutrient in nutrients}  # Initialize sum

# Process each ingredient and sum the values
for ingredient in ingredients:
    for nutrient in nutrients:
        totals[nutrient] += (float(ingredient[nutrient]) * float(ingredient["AMOUNT"]) / total_weight)

# Format and print total values
output = {
    "Servings Per Package": servings_per_package,
    "Serving Size": f"{serving_size:.2f} g",
    "Energy": f"{totals['ENERGY']:.2f} kJ",
    "Protein": f"{totals['PROTEIN']:.2f} g",
    "Fat (Total)": f"{totals['FAT']:.2f} g",
    "Saturated Fat": f"{totals['SATURATED']:.2f} g",
    "Carbohydrate (Total)": f"{totals['CARBOHYDRATE']:.2f} g",
    "Sugars": f"{totals['SUGARS']:.2f} g",
    "Sodium": f"{totals['SODIUM']:.2f} mg"
}

print(json.dumps(output, indent=2))
