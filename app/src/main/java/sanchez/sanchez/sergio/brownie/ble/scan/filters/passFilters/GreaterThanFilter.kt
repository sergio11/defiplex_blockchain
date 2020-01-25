package sanchez.sanchez.sergio.brownie.ble.scan.filters.passFilters

import android.bluetooth.le.ScanResult
import sanchez.sanchez.sergio.brownie.ble.scan.filters.scanResultValues.IScanResultValue

/**
 * Objective of the document:
 */
class GreaterThanFilter (val value : String, val scanResultValue : IScanResultValue):
        IPassFilter {

    override fun passFilter(scanResult: ScanResult) : Boolean {
        return (scanResultValue.getValue(scanResult).compareTo(value) == 1)
    }

}