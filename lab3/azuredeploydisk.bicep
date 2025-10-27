resource disk3 'Microsoft.Compute/disks@2022-07-02' = {
  name: 'az104-disk3'
  location: 'germanywestcentral'
  sku: {
    name: 'StandardSSD_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 32
  }
}
