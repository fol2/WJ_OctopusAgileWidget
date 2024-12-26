import CoreData
import Foundation

class CoreDataService {
    static let shared = CoreDataService()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WJ_OctopusAgile")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func fetchAgileRates() -> [AgileRatesEntity] {
        let fetchRequest: NSFetchRequest<AgileRatesEntity> = AgileRatesEntity.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch Agile Rates: \(error)")
            return []
        }
    }
    
    func saveAgileRates(_ rates: [AgileRate]) {
        for rate in rates {
            let fetchRequest: NSFetchRequest<AgileRatesEntity> = AgileRatesEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", rate.id as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let existingRate = results.first {
                    // Update existing rate
                    existingRate.validFrom = rate.validFrom
                    existingRate.validTo = rate.validTo
                    existingRate.valueExcVat = rate.valueExcVat
                    existingRate.valueIncVat = rate.valueIncVat
                } else {
                    // Create new rate
                    let newRate = AgileRatesEntity(context: context)
                    newRate.id = rate.id
                    newRate.validFrom = rate.validFrom
                    newRate.validTo = rate.validTo
                    newRate.valueExcVat = rate.valueExcVat
                    newRate.valueIncVat = rate.valueIncVat
                }
            } catch {
                print("Error fetching rate: \(error)")
            }
        }
        
        saveContext()
    }
    
    func cleanupOldRates() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = AgileRatesEntity.fetchRequest()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        fetchRequest.predicate = NSPredicate(format: "validTo < %@", threeDaysAgo as NSDate)
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
        } catch {
            print("Error cleaning up old rates: \(error)")
        }
    }

    func resetAllData(completion: @escaping (Bool) -> Void) {
    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = AgileRatesEntity.fetchRequest()
    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
    do {
        try context.execute(batchDeleteRequest)
        saveContext()
        completion(true)
    } catch {
        print("Error resetting data: \(error)")
        completion(false)
    }
}
}
