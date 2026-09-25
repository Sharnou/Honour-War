#pragma once
#include <array>
#include <string>
#include <vector>
#include <DirectXMath.h>
#include <nlohmann/json.hpp>

namespace Sharnou {

class D3D11Renderer;

enum class HonourClass { Warrior, Mage, Archer, Thief, Acolyte, Merchant, Ranger };

struct Skill {
    std::string name;
    float powerRatio{1.0f};
    int resourceCost{10};
};

struct Character {
    std::string username{"player"};
    std::string characterName{"Adventurer"};
    HonourClass classId{HonourClass::Warrior};
    int level{1};
    int ageDays{0};
    double onlineSeconds{0.0};
    int hp{100};
    int maxHp{100};
    int sp{100};
    int maxSp{100};
    DirectX::XMFLOAT3 position{0.0f, 1.0f, 0.0f};
    DirectX::XMFLOAT3 moveTarget{0.0f, 1.0f, 0.0f};
    bool moving{false};
    std::array<int, 8> skillLevels{1,1,1,1,1,1,1,1};
};

struct Monster {
    std::string id;
    std::string name;
    int level{1};
    int hp{100};
    int maxHp{100};
    DirectX::XMFLOAT3 position{0,0,0};
    bool alive{true};
};

class HonourWarGame {
public:
    bool Initialize();
    void Update(float dt);
    void Render(D3D11Renderer& renderer);
    void OnLeftClick(int x, int y);
    void OnRightDrag(float dx, float dy);
    void OnMouseWheel(float delta);
    void OnKeyDown(unsigned int key);
    void SubmitCommand(const std::string& command);
    bool RunSelfTest();
    bool RunRuntimeSoak(int simulatedSeconds);

private:
    bool LoadCanonicalData();
    void SaveGame();
    void LoadGame();
    void ActivateSkill(int slot);
    void MoveTowardTarget(float dt);
    void RecalculateAge();

    std::string dataRoot_;
    Character player_;
    std::vector<Monster> monsters_;
    int selectedMonster_{-1};
    float cameraYaw_{45.0f};
    float cameraPitch_{50.0f};
    float cameraDistance_{18.0f};
    std::array<Skill, 8> skills_;
    nlohmann::json catalog_;
    nlohmann::json classJobs_;
    nlohmann::json characterProfiles_;
    nlohmann::json skillSystem_;
    float saveAccumulator_{0.0f};
    void ReloadSkillsForCurrentClass();
    static const char* ClassName(HonourClass c);
};

}
