module repowdered.particles.creating.ui;

import repowdered.particles.loading;
import repowdered.sednapipeline;
import repowdered.particles.creating.spawner;
import repowdered.ui;
import plutoecs;
import sednalib;

package void initUICreating(World world, ParticleSpawnerSystem spawner)
{
    auto uiSystem = new CreateUISystem(spawner);
    world.addSystem!CreateUISystem(uiSystem);
}

/// System that creates all UI for particle creating
private final class CreateUISystem
{
    mixin SystemMembers;
    private ParticleSpawnerSystem spawner;
    private Frame categoriesRoot;
    private Frame typesRoot;

    public this(ParticleSpawnerSystem spawner)
    {
        this.spawner = spawner;
    }

    public void start()
    {
        SednalibPipeline.addOnceRenderTask(&createUI);
    }

    private void createUI(Window window)
    {
        createModulesUI();
    }

    /// Creates modules button and modules pop-up list
    private void createModulesUI()
    {
        import cereslib.todo;
        // I'm sure this symbol will never be changed
        mixin TODO!"Find a better replace for modules symbol, but it should be international";

        auto root = GameUIRoots.upperActionsFrame;
        ScrollFrame modulesPopupFrame = vscrollFrame();
        foreach(module_; globalLoadedModules)
        {       
            // Why so strange? See https://forum.dlang.org/thread/pjrdlgtahzfppoxojxls@forum.dlang.org
            auto updateCategories = (mdl) @safe
            {
                return () @safe
                {
                    updateCategoriesUI(mdl);
                };
            }(module_);

            auto selectButton = button(module_.name, updateCategories);

            selectButton.theme = Themes.defaultUIElement;
            modulesPopupFrame.children ~= selectButton;
        }
        modulesPopupFrame.theme = Themes.defaultUIElement;
        modulesPopupFrame.updateSize();

        auto modulesButton = popupButton("Modules", modulesPopupFrame);
        modulesButton.popup.theme = Themes.defaultUIElement;
        modulesButton.layout = layout!(1, "end", "end"),
        root.children ~= modulesButton;
        root.updateSize();
    }

    /// Creates or updates list of category buttons
    private void updateCategoriesUI(Module selectedModule) @safe
    {
        if(categoriesRoot !is null)
        {
            categoriesRoot.remove();
        }

        categoriesRoot = vscrollFrame(.layout!(1, "end", "start"));

        foreach(category; selectedModule.categories)
        {
            auto updateTypes = (ctg) @safe
            {
                return () @safe
                {
                    updateTypesUI(ctg);
                };
            }(category);

            auto selectButton = button(category.name, updateTypes);

            selectButton.theme = Themes.defaultUIElement;
            categoriesRoot.children ~= selectButton;
        }

        categoriesRoot.updateSize();

        GameUIRoots.contentFrame.children ~= categoriesRoot;
        GameUIRoots.contentFrame.updateSize();
    }

    /// Creates or recreates list of type buttons
    private void updateTypesUI(Category category) @safe
    {
       if(typesRoot !is null)
        {
            typesRoot.remove();
        }

        typesRoot = hscrollFrame(.layout!(1, "end", "end"));

        foreach(type; category.types)
        {
            auto selectType = (tp) @safe
            {
                return () @trusted
                {
                    spawner.selectType(tp);
                };
            }(type);

            auto selectButton = button(type.typeName, selectType);

            selectButton.theme = Themes.defaultUIElement;
            typesRoot.children ~= selectButton;
        }
        typesRoot.updateSize();
        
        GameUIRoots.typesFrame.children ~= typesRoot;
        GameUIRoots.contentFrame.updateSize();
    }
}