import Foundation

private struct PaginatedResponse<T: Decodable>: Decodable {
    var items: [T]
    var total: Int
    var page: Int
    var pageSize: Int
    var pages: Int
}

struct AdminAccountsAPI {
    let site: SiteConfiguration
    let client: APIClient

    init(site: SiteConfiguration, client: APIClient = APIClient()) {
        self.site = site
        self.client = client
    }

    func fetchDashboardStats() async throws -> AdminDashboardStatsDTO {
        try await client.get(AdminDashboardStatsDTO.self, site: site, path: "/admin/dashboard/stats")
    }

    func fetchDashboardSnapshot() async throws -> AdminDashboardSnapshotDTO {
        try await client.get(AdminDashboardSnapshotDTO.self, site: site, path: "/admin/dashboard/snapshot-v2")
    }

    func fetchAccounts() async throws -> [AdminAccountDTO] {
        var accounts: [AdminAccountDTO] = []
        var page = 1
        var totalPages = 1

        repeat {
            let response = try await client.get(
                PaginatedResponse<AdminAccountDTO>.self,
                site: site,
                path: "/admin/accounts",
                queryItems: [
                    URLQueryItem(name: "page", value: "\(page)"),
                    URLQueryItem(name: "page_size", value: "100")
                ]
            )

            accounts.append(contentsOf: response.items)
            totalPages = max(response.pages, 1)
            page += 1
        } while page <= totalPages

        return accounts
    }

    func fetchUsages(accounts: [AdminAccountDTO]) async -> [Int: AccountUsageInfoDTO] {
        let accountIDs = accounts
            .filter { $0.extra?.hasCompleteCodexWindowSnapshot != true }
            .map(\.id)
        return await withTaskGroup(of: (Int, AccountUsageInfoDTO?).self, returning: [Int: AccountUsageInfoDTO].self) { group in
            for accountID in accountIDs {
                group.addTask {
                    do {
                        return (accountID, try await fetchUsage(accountID: accountID))
                    } catch {
                        return (accountID, nil)
                    }
                }
            }

            var result: [Int: AccountUsageInfoDTO] = [:]
            for await (accountID, usage) in group {
                if let usage {
                    result[accountID] = usage
                }
            }
            return result
        }
    }

    func fetchUsages(accountIDs: [Int]) async -> [Int: AccountUsageInfoDTO] {
        await fetchUsages(
            accounts: accountIDs.map {
                AdminAccountDTO(
                    id: $0,
                    name: "",
                    platform: "",
                    type: "",
                    currentConcurrency: nil,
                    status: "active",
                    schedulable: true,
                    lastUsedAt: nil,
                    rateLimitedAt: nil,
                    rateLimitResetAt: nil,
                    overloadUntil: nil,
                    tempUnschedulableUntil: nil,
                    errorMessage: nil
                )
            }
        )
    }

    private func fetchUsage(accountID: Int) async throws -> AccountUsageInfoDTO {
        try await client.get(
            AccountUsageInfoDTO.self,
            site: site,
            path: "/admin/accounts/\(accountID)/usage",
            queryItems: [URLQueryItem(name: "source", value: "active")]
        )
    }
}
