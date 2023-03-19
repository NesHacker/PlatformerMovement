


function generateWalkFrameDelayTable (delayMax, delayMin) {
  const delay = (v, max, min) => Math.floor(max - ((max - min)/40) * v)

  const table = []
  for (let v = 0; v <= 40; v++) {
    table.push(delay(v, delayMax, delayMin))
  }
  console.log(`.byte ${table.join(', ')}`)
}

generateWalkFrameDelayTable(12, 4)

