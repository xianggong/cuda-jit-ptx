#!/usr/bin/python
import sys


class genKernel(object):

    def __init__(self, aluWndwSz, memDist, kernelName, mode):
        self.aluWindowSize = aluWndwSz
        self.memDistance = memDist
        self.kernelName = kernelName
        self.mode = mode

    def genRead(self, index, bufName):
        src = ""
        with open("kernelRead.tpl") as kernelFile:
            src = kernelFile.read()
        src = src.replace("INDEX", str(index))
        src = src.replace("BUFNAME", bufName)
        return src

    def genALU(self, kernelIdx, bufName):
        src = "  ; ALU on " + bufName + "\n"
        src += "  %k" + str(kernelIdx) + ".alu." + \
            bufName + ".0 = fdiv float %k"
        src += str(kernelIdx) + ".val" + bufName + ", 1.0\n"
        for i in range(self.aluWindowSize):
            src += "  %k" + str(kernelIdx) + ".alu." + \
                bufName + "." + str(i + 1)
            src += " = fdiv float %k" + str(kernelIdx) + ".alu." + bufName
            src += "." + str(i) + ", " + str(i + 1) + ".0\n"
        src += "  %k" + str(kernelIdx) + ".alu." + \
            bufName + ".last = fdiv float %k"
        src += str(kernelIdx) + ".alu." + bufName + "." + \
            str(self.aluWindowSize) + ", 1.0\n"
        src += "\n"
        return src

    def genK(self, kernelIdx):
        src = ""
        aluSrc = ""
        if self.mode == 0:
            src += self.genRead(kernelIdx, "A")
            src += self.genALU(kernelIdx, "A")
            src += self.genRead(kernelIdx, "B")
            src += self.genALU(kernelIdx, "B")
            src += self.genRead(kernelIdx, "C")
            src += self.genALU(kernelIdx, "C")
        elif self.mode == 1:
            src += self.genRead(kernelIdx, "A")
            src += self.genRead(kernelIdx, "B")
            src += self.genRead(kernelIdx, "C")
            src += self.genALU(kernelIdx, "A")
            src += self.genALU(kernelIdx, "B")
            src += self.genALU(kernelIdx, "C")
        elif self.mode == 2:
            src += self.genRead(kernelIdx, "A")
            aluSrc = self.genALU(kernelIdx, "A")
            aluSrc += self.genALU(kernelIdx, "B")
            aluSrc += self.genALU(kernelIdx, "C")
            aluSrcLine = aluSrc.splitlines(True)
            count = 0
            if kernelIdx == 1:
                count -= memDistance / 2
            for line in aluSrcLine:
                src += line
                if count % memDistance == 0:
                    if count / memDistance == 1:
                        src += "\n"
                        src += self.genRead(kernelIdx, "B")
                    if count / memDistance == 2:
                        src += "\n"
                        src += self.genRead(kernelIdx, "C")
                count += 1
        else:
            print("Error mode")
        return src

    def genIR(self):
        kernelSrc = ""
        k0Src = ""
        k1Src = ""
        with open("kernel.tpl") as kernelFile:
            kernelSrc = kernelFile.read()
        k0Src = self.genK(0)
        k1Src = self.genK(1)
        kernelSrc = kernelSrc.replace("K0_AUTOGEN", k0Src)
        kernelSrc = kernelSrc.replace("K1_AUTOGEN", k1Src)
        return kernelSrc

    def dump(self):
        kernelFile = open(self.kernelName + "_" + str(self.aluWindowSize) +
                          "_" + str(self.memDistance) + ".ll", "w+")
        kernelFile.write(self.genIR())

if __name__ == "__main__":
    aluWindowSize = int(sys.argv[1])
    memDistance = int(sys.argv[2])
    if aluWindowSize <= memDistance:
        memDistance = 1

    kernel0 = genKernel(aluWindowSize, memDistance, "kernel0", 0)
    kernel0.dump()

    kernel1 = genKernel(aluWindowSize, memDistance, "kernel1", 1)
    kernel1.dump()

    kernel2 = genKernel(aluWindowSize, memDistance, "kernel2", 2)
    kernel2.dump()
