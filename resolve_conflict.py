import re

file_path = 'lib/features/gravity_balance/gravity_balance_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Pattern to match conflict blocks
pattern = re.compile(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> .*?\n', re.DOTALL)

def replace_with_head(match):
    return match.group(1) + '\n'

# Replace all conflicts with HEAD content
# Use sub with count=0 (all)
new_content = re.sub(r'<<<<<<< HEAD\n(.*?)=======\n(.*?)>>>>>>> .*?\n', lambda m: m.group(1), content, flags=re.DOTALL)

with open(file_path, 'w') as f:
    f.write(new_content)
