import re
from resources import Register


class ReBuffer:
    text: str

    def __init__(self, text=""):
        self.text = text

    def search(self, pattern: str | re.Pattern[str], flags=0):
        match = re.search(pattern, self.text, flags)
        if match is not None:
            self.text = self.text[match.end() - 1 :]
        return match


print("Enter/Paste your content. Ctrl-D or Ctrl-Z ( windows ) to save it.")
text = []
while True:
    try:
        line = input()
    except EOFError:
        break
    if line == "":
        break
    text.append(line)

text = ReBuffer("\n".join(text))

num_param = int(text.search(r"^NumParameters\s+(\d+)", re.MULTILINE).group(1))

signature = ""


def gen_registers_range(reg=0, space=0, prefix="b", count=1):
    reg = int(reg)
    count = int(count)
    text = ""
    if count > 1000:
        return f"{{{{RTXStub.buffers.{prefix+str(reg)}_space{space}}}}} // {count}\n"
    for i in range(reg, reg + count):
        text += f"{{{{RTXStub.buffers.{prefix+str(i)}_space{space}}}}}\n"
    return text


for _ in range(num_param):
    type = text.search(r"^Root Parameter Type\s+(\w+)", re.MULTILINE).group(1)

    if type != "DESCRIPTOR_TABLE":
        signature += f"// {type}\n"
        match = text.search(
            r"^ShaderRegister\s+(\d+)\s+RegisterSpace\s+(\d+)",
            re.MULTILINE,
        )
        signature += gen_registers_range(match.group(1), match.group(2)) + "\n"
        continue

    num = int(text.search(r"^Descriptor Range Count\s+(\d+)", re.MULTILINE).group(1))

    signature += f"// {type} [{num}]\n"
    for _ in range(num):
        match = text.search(
            r"^RangeType\s+(\w+)\s+NumDescriptors\s+(\d+)\s+BaseShaderRegister\s+(\d+)\s+RegisterSpace\s+(\d+)",
            re.MULTILINE,
        )
        prefix = {"CBV": "b", "SRV": "t", "SAMPLER": "s", "UAV": "u"}[match.group(1)]
        signature += f"// {match.group(1)}[{match.group(2)}]\n"
        signature += (
            gen_registers_range(match.group(3), match.group(4), prefix, match.group(2))
            + "\n"
        )


print(signature)
