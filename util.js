


function generateWalkFrameDelayTable (delayMax, delayMin) {
  const delay = (v, max, min) => Math.floor(max - ((max - min)/40) * v)

  const table = []
  for (let v = 0; v <= 40; v++) {
    table.push(delay(v, delayMax, delayMin))
  }
  console.log(`.byte ${table.join(', ')}`)
}

function generateVXIndicator (zeroPos) {

  const delta = 22 / 80
  let negativePos = zeroPos - 11
  let positivePos = zeroPos + delta

  const negative = []
  const positive = []


  for (let k = 1; k <= 40; k++) {
    negative.push(Math.floor(negativePos))
    negativePos += delta
    positive.push(Math.floor(positivePos))
    positivePos += delta
  }

  console.log(`.byte ${[].concat(negative, [zeroPos], positive).join(', ')}`)
}

function generateVYIndicator () {
  const [min, zero, max] = [189, 200, 211]
  const [minV, maxV] = [-56, 64]


  const step = (max - min) / (maxV - minV)

  let pos = min

  const bytes = []
  for (let k = 0; k <= maxV - minV; k++) {
    bytes.push(Math.floor(pos))
    pos += step
  }

  console.log(`.byte ${bytes.join(', ')}`)
}


// generateWalkFrameDelayTable(12, 4)
// generateVXIndicator(89)
generateVYIndicator()
