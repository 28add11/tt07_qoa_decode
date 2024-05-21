<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Explain how your project works

## How to test

Connect the chip to a mode 0 SPI master, with a clock rate at least 6x slower than the chip clock. Then, fill the LMS history and weights, by using the following instruction:
| bit[7] | bit[6] | bit[5] | bit[4] | bit[3] | bit[2] | bit[1] | bit[0] |
| ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ |
|       |      |      |      | Adress[1] | Adress[0] | BankSel |   0    |

BankSel chooses between history and weights, 1 for weights and 0 for history. Adress is just which of the 4 values to fill, as specified by QOA. The next two bytes are the data to fill the history or weights with, MSB first.
If you want to then send a sample, the following instruction is used:
| bit[7] | bit[6] | bit[5] | bit[4] | bit[3] | bit[2] | bit[1] | bit[0] |
| ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ |
| sf_quant[3] | sf_quant[2] | sf_quant[1] | sf_quant[0] | qr[2] | qr[1] | qr[0] |   1    |

qr and sf_quant are exactly as they are in the QOA specification, with this chip decoding sample by sample.

After sending the sample, wait (NUMBER) chip clock cycles, then request the sample with the following instruction:
| bit[7] | bit[6] | bit[5] | bit[4] | bit[3] | bit[2] | bit[1] | bit[0] |
| ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ |
|   1    |        |        |        |        |        |        |   0    |

Once you send that instruction, the next two bytes sent by the chip will be the decoded sample!

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
